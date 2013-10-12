require "erb"
require "fileutils"
require "logger"
require "pp"

require "uuidtools"
require "open3"
require "thread"
require "uri"

module VCAP
  module Services
    module MSSQL
      class Node < VCAP::Services::Base::Node
        class ProvisionedService
        end
      end
    end
  end
end

require "mssql_service/common"
require "mssql_service/util"

class VCAP::Services::MSSQL::Node
  include VCAP::Services::MSSQL::Common

  def initialize(options)
    super(options)
    @mssql_configs = options[:mssql]


    @base_dir = options[:base_dir]
    @local_db = options[:local_db]    
  end

  def pre_send_announcement
    FileUtils.mkdir_p(@base_dir) if @base_dir

    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, @local_db)
    DataMapper::auto_upgrade!

    @capacity_lock.synchronize do
      mssqlProvisionedService.all.each do |instance|
        @capacity -= capacity_unit
      end
    end

    #todo: check connection for db instance

  end

  def varz_details
    varz = super
    varz[:yisuiandzhuangyuan] = 'loveyouforever'
    
    # provisioned services status
    varz[:instances] = {}
    begin
      mssqlProvisionedService.all.each do |instance|
        varz[:instances][instance.name.to_sym] = get_status(instance)
      end
    rescue => e
      @logger.error("Error get instance list: #{e}")
    end

    provisioned_service = mssqlProvisionedService.create(1111, UUIDTools::UUID.random_create.to_s.gsub(/-/, ''), 'sa', 'sa', 'version')

    provisioned_service.run do
      log provisioned_service
    end

    log varz
    varz
  end

  def get_status(instance)
    res = "ok"
    host, port, root_user, root_pass = instance_configs(instance)

    #todo: check db instance status: 
    # 1) check process status of db instance;
    # 2) connect to it and execut valid query

    res
  end

  # provision(plan) --> {name, host, port, user, password}, {version}
  def provision
  end
  
  # unprovision(name) --> void
  def unprovision
  end

  # bind(name, bind_opts) --> {host, port, login, secret}
  def bind
  end

  # unbind(credentials)  --> void
  def unbind
  end

  # announcement() --> { any service-specific announcement details }
  def announcement
    @capacity_lock.synchronize do
      {
        :available_capacity => @capacity,
        :max_capacity => @max_capacity,
        :capacity_unit => capacity_unit
      }
    end
  end

  # return configuration of specific instance
  def instance_configs(instance)
    return unless instance
    config = @mssql_configs[instance.version]
    result = %w{host port user pass}.map { |opt| config[opt] }

    log result
    result
  end
  
  def mssqlProvisionedService
    VCAP::Services::MSSQL::Node::ProvisionedService
  end

  class VCAP::Services::MSSQL::Node::ProvisionedService
    include DataMapper::Resource

    property :name, String, :key => true
    property :user, String, :required => true
    property :password, String, :required => true
    property :plan, Integer, :required => true
    property :quota_exceeded, Boolean, :default => false
    property :version, String

    class << self
      def create(port, name, user, password, version)
        provisioned_service = new
        provisioned_service.name = name
        provisioned_service.user = user
        provisioned_service.password = password
        provisioned_service.plan = 1
        provisioned_service.version = version
        provisioned_service
      end

      #no-ops methods
      def method_missing(method_name, *args, &block)
        no_ops = [:init]
        super unless no_ops.include?(method_name)
      end
    end

    def run
      yield self if block_given?
      save
    end
  end

end