require "rubygems"
require "rspec"
require "bundler/setup"
require "yajl"
require "fileutils"
require 'tiny_tds'
require "vcap_services_base"

require_relative "../lib/mssql_service/util"
require_relative "../lib/mssql_service/node"
require_relative "../lib/mssql_service/common"
require_relative "../lib/mssql_service/job"

include VCAP::Services::MSSQL::Util

module Boolean; end
class ::TrueClass; include Boolean; end
class ::FalseClass; include Boolean; end

def getLogger()
  logger = Logger.new(STDOUT)
  logger.level = Logger::ERROR

  logger
end

def getNodeTestConfig
  config_file = File.expand_path("../config/mssql_node.yml", File.dirname(__FILE__))
  config = YAML.load_file(config_file)
  spec_tmp_dir = parse_property(config, "base_dir", String)

  options = {
    # service node related configs
    :logger             => getLogger,
    :plan               => parse_property(config, "plan", String),
    :capacity           => parse_property(config, "capacity", Integer),
    :node_id            => parse_property(config, "node_id", String),
    :mbus               => parse_property(config, "mbus", String),
    :ip_route           => parse_property(config, "ip_route", String, :optional => true),
    :supported_versions => parse_property(config, "supported_versions", Array),
    :default_version    => parse_property(config, "default_version", String),

    # service instance related configs
    :mssql                   => parse_property(config, "mssql", Hash),
    :max_db_size             => parse_property(config, "max_db_size", Integer),
    :max_long_query          => parse_property(config, "max_long_query", Integer),
    :connection_pool_size    => parse_property(config, "connection_pool_size", Hash),
    :max_long_tx             => parse_property(config, "max_long_tx", Integer),
    :kill_long_tx            => parse_property(config, "kill_long_tx", Boolean),
    :max_user_conns          => parse_property(config, "max_user_conns", Integer, :optional => true),
    :connection_wait_timeout => 10,
    :max_disk                => parse_property(config, "max_disk", Integer),

    # unit test directories of mssql unit test to /tmp
    :base_dir => File.join(spec_tmp_dir, "spec", "data"),
    :local_db => File.join("sqlite3:", spec_tmp_dir, "spec", "mssql_node.db"),
    :database_lock_file => File.join(spec_tmp_dir, "spec", "LOCK"),
    :disabled_file => File.join(spec_tmp_dir, "spec", "DISABLED"),
    :ip_route => "127.0.0.1",
    :status => parse_property(config, "status", Hash).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  }

  options
end

def parse_property(hash, key, type, options = {})
  obj = hash[key]
  if obj.nil?
    raise "Missing required option: #{key}" unless options[:optional]
    options[:default]
  elsif type == Range
    raise "Invalid Range object: #{obj}" unless obj.kind_of?(Hash)
    first, last = obj["first"], obj["last"]
    raise "Invalid Range object: #{obj}" unless first.kind_of?(Integer) and last.kind_of?(Integer)
    Range.new(first, last)
  else
    raise "Invalid #{type} object: #{obj}" unless obj.kind_of?(type)
    obj
  end
end

def get_mssql_conn(username, password, host, port=nil)
  TinyTds::Client.new(:username => username, :password => password, :host => host, :port => port || 1433)
end

def gen_credential(node_id, database, username, password, host, port)
  {
    "node_id" => node_id,
    "name" => database,
    "hostname" => host,
    "host" => host,
    "port" => port,
    "user" => username,
    "username" => username,
    "password" => password,
    "uri" => generate_uri(username, password, host, port, database)
  }
end

def generate_uri(username, password, host, port, database)
  scheme = 'mssql'
  credentials = "#{username}:#{password}"
  path = "/#{database}"

  uri = URI::Generic.new(scheme, credentials, host, port, nil, path, nil, nil, nil)
  uri.to_s
end


