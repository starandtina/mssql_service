# Copyright (c) 2013-2015 VMware, Inc.
require "fileutils"
require "data_mapper"

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

require_relative "./common"
require_relative "./util"
require_relative "./cmd_runner"
require_relative "./mssql_error"

class VCAP::Services::MSSQL::Node
  include VCAP::Services::MSSQL::Common
  include VCAP::Services::MSSQL::Util

  def initialize(options)
    super(options)

    @mssql_configs = options[:mssql]

    @logger.debug get_host
    @logger.debug @local_ip

    @base_dir = options[:base_dir]
    @local_db = options[:local_db]

    #mutex defined
    @varz_lock = Mutex.new
    @provision_lock = Mutex.new
    @delete_user_lock = Mutex.new

    #record number of provisioned
    @provision_served = 0
  end

  def pre_send_announcement
    FileUtils.mkdir_p(@base_dir) if @base_dir

    #DataMapper::Logger.new($stdout, :debug)
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

    varz[:max_capacity] = @max_capacity
    varz[:available_capacity] = @capacity
    varz[:used_capacity] = @max_capacity - @capacity

    # provisioned services status
    varz[:instances] = {}
    begin
      mssqlProvisionedService.all.each do |instance|
        varz[:instances][instance.name.to_sym] = get_status(instance)
      end
    rescue => e
      @logger.error("Error get instance list: #{e}")
    end

    # how many provision operations since startup.
    @varz_lock.synchronize do
      varz[:provision_served] = @provision_served
    end

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

  def all_instances_list
    mssqlProvisionedService.all.map { |s| s.name }
  end

  # respond to "svc.heartbeat" nats message
  def get_instance_health(instance_name)
    instance = mssqlProvisionedService.get(instance_name)
    health = instance.nil? ? 'fail' : get_status(instance)
    { :health => health }
  end

  # provision(plan, credential, version) --> {name, host, port, user, password}, {version}
  def provision(plan, credential, version=nil)
    raise ServiceError.new(ServiceError::UNSUPPORTED_VERSION, version) unless @supported_versions.include?(version)

    begin
      port, name, user, password = %w(port name user password).map { |key| credential[key] }
      provisioned_service = mssqlProvisionedService.create(name, user, password, version)
      provisioned_service.run do |instance|
        raise "Fail to create database" unless create_database instance
      end
      @provision_lock.synchronize do
        @provision_served += 1
      end
      credential
    rescue => e
      delete_database(provisioned_service) if provisioned_service
      raise e
    end
  end

  # unprovision(name) --> void
  def unprovision(name, credentials)
    return if name.nil?
    @logger.debug("Unprovision database:#{name} and its #{credentials.size} bindings")
    provisioned_service = mssqlProvisionedService.get(name)
    raise MSSQLError.new(MSSQLError::MSSQL_CONFIG_NOT_FOUND, name) if provisioned_service.nil?
    return false unless delete_database(provisioned_service)
    @logger.debug("Successfully unprovision request: #{name}")
    true
  end

  # bind(name, bind_opts) --> {host, port, login, secret}
  def bind
  end

  # unbind(credentials)  --> void
  def unbind(credential)
    name, user = %w(name user).map { |k| credential[k] }
    @logger.debug "Unbind #{user} for #{name}"
    delete_database_user(user, name)
  end

  # announcement() --> { any service-specific announcement details }
  def announcement
    @capacity_lock.synchronize do
      {
        :available_capacity => @capacity,
        :max_capacity => @max_capacity,
        :capacity_unit => capacity_unit,
        :host => get_host
      }
    end
  end

  # return configuration of specific instance
  def instance_configs(instance)
    return unless instance
    config = @mssql_configs[instance.version]
    result = %w{host port user pass}.map { |opt| config[opt] }

    result
  end

  def create_database(provisioned_service)
    name, password, user = [:name, :password, :user].map { |key| provisioned_service.send(key) }

    begin
      start = Time.now
      @logger.debug "Creating Database: #{provisioned_service.inspect}"

      CMDRunner.run("create_partial_db", :timeout => 10, :params => { :DatabaseName => "#{name}" }) do |cmd, status|
        raise "CMD '#{cmd}' exit with status: #{status}." if status != 0
      end
      create_database_user(name, user, password)
      @logger.debug "Creating Database Done: #{provisioned_service.inspect}. Took #{Time.now - start}s."
      true
    rescue => e
      @logger.warn "Could not create database: #{e}"
      false
    end
  end

  def delete_database(provisioned_service)
    name = provisioned_service.send(:name)

    begin
      CMDRunner.run("del_partial_db", :timeout => 10, :params => { :DatabaseName => "#{name}" }) do |cmd, status|
        raise "CMD '#{cmd}' exit with status: #{status}." if status != 0
      end
    rescue => e
      @logger.warn "Could not del database: #{e}"
      false
    end
  end

  def create_database_user(name, user, password)
    CMDRunner.run("create_partial_db_user", :timeout => 3, :params => { :DatabaseName => "#{name}", :UserName => user, :Password => password }) do |cmd, status|
      raise "CMD '#{cmd}' exit with status: #{status}." if status != 0
    end
  end

  def delete_database_user(user, name)
    @logger.debug("Delete user #{user}")
    @delete_user_lock.synchronize do
      begin
        CMDRunner.run("del_partial_db_user", :timeout => 3, :params => { :DatabaseName => "#{name}", :UserName => user }) do |cmd, status|
          raise "CMD '#{cmd}' exit with status: #{status}." if status != 0
        end
      rescue => e
        @logger.warn "Could not del database user: #{e}"
        false
      end
    end
  end

  def get_host
    return @host if @host

    host = @mssql_configs.values.first['host']
    if ['localhost', '127.0.0.1'].include?(host)
      host = super
    end

    @host = host
    @host
  end

  def mssqlProvisionedService
    VCAP::Services::MSSQL::Node::ProvisionedService
  end
end

class VCAP::Services::MSSQL::Node::ProvisionedService
  include DataMapper::Resource

  property :name, String, :key => true
  property :user, String, :required => true
  property :password, String, :required => true
  property :version, String, :required => true, :default => "free"

  class << self
    def create(name, user, password, version)
      provisioned_service = new
      provisioned_service.name = name
      provisioned_service.user = user
      provisioned_service.password = password
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
