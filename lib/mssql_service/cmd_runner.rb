# Copyright (c) 2013-2015 VMware, Inc.
require "timeout"

class VCAP::Services::MSSQL::Node::CMDRunner
  def initialize(cmd)
    @cmd = cmd
  end

  def exec(options, &blk)
    @timeout = options[:timeout] || 10
    @params = options[:params]

    if @params
      sql_params = '-v'
      @params.each do |key, value|
        sql_params += " #{key.to_s}=#{value}"
      end
    else
      sql_params = ''
    end

    #SQLCMD: refer to http://msdn.microsoft.com/en-us/library/ms162773.aspx
    sql_file = File.expand_path("../../bin/#{@cmd}.sql", File.dirname(__FILE__)).tr('/', '\\')
    sqlcmd = "SQLCMD -E -h-1 -w255 -b -V1 -i #{sql_file} #{sql_params}"
    status = -1
    pid = Process.spawn sqlcmd
  
    begin
      Timeout::timeout(@timeout) do
        Process.waitpid(pid)
      end
      status = $?.exitstatus
    rescue Timeout::Error
      Process.detach(pid)
      Process.kill("KILL", pid)
    end

    blk.call(sqlcmd, status) if blk

    status == 0 ? true : false
  end

  def self.run(cmd, options={}, &blk)
    instance = self.new cmd
    instance.exec options, &blk
  end
end
