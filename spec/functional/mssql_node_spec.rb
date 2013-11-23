require "erb"
require "securerandom"

require_relative "../spec_helper"

describe "MSSQL Node Functional Test" do
  include VCAP::Services::MSSQL

  before :each do
    @opts = getNodeTestConfig
    @opts.freeze
    @default_plan = "free"
    @default_version = @opts[:default_version]

    # Setup code must be wrapped in EM.run
    EM.run do
      @node = VCAP::Services::MSSQL::Node.new(@opts)
      EM.add_timer(1) { EM.stop }
    end
  end

  context "when provision database" do
    before :each do
      @node_id = "mssql_node_free" + SecureRandom.uuid.to_s.gsub(/-/, '')
      @db_name = "d" + SecureRandom.uuid.to_s.gsub(/-/, '')
      @user = "u" + SecureRandom.uuid.to_s.gsub(/-/, '')
      @password = "p" + SecureRandom.uuid.to_s.gsub(/-/, '')[0, 20]
      @host = "localhost"
      @port = 1433
      @credential = gen_credential(@node_id, @db_name, @user, @password, @host, @port)
    end

    it "should able to provision partially database" do
      db = @node.provision(@default_plan, @credential, @default_version)
      db.should_not be_nil
      db["name"].should eq @db_name
      db["host"].should eq @host
      db["host"].should eq db["hostname"]
      db["user"].should eq db["username"]
      db["user"].should eq @user
      db["password"].should eq @password
      db["port"].should eq @port

      mssql_conn = get_mssql_conn("sa", "password", db["host"], db["port"])
      result = mssql_conn.execute("SELECT name FROM [sys].[databases] where name = '#{db["name"]}'")
      first_row = result.each.first
      result.each.should be_instance_of Array
      first_row.should be_instance_of Hash
      first_row["name"].should eq db["name"]
      mssql_conn.close
    end

    it "should rails service error if encountered unsupported MSSQL version" do
      unsupported_version = "unsupported_version"
      error_code = 30004
      error_msg = "Unsupported version #{unsupported_version}"
      lambda { @node.provision(@default_plan, @credential, unsupported_version) }.should raise_error VCAP::Services::Base::Error::ServiceError, "Error Code: #{error_code}, Error Message: #{error_msg}" do |error|
          p error
        end
    end
  end

  context "when generate varz/configuration" do
    it "should able to generate varz." do
      EM.run do
        EM.add_timer(1) do
          varz = @node.varz_details

          varz.should be_instance_of Hash

          varz[:max_capacity].should > 0
          varz[:available_capacity].should >= 0
          varz[:used_capacity].should eq (varz[:max_capacity] - varz[:available_capacity] )
          varz[:provision_served].should be >= 0
          EM.stop
        end
      end
    end

    it "should able to generate mssql_node yaml" do
      mssql_node_erb = File.expand_path("../../config/mssql_node.yml.erb", File.dirname(__FILE__))
      index = 1
      nats = "nats://10.110.124.219:4222"
      erb = ERB.new(File.read(mssql_node_erb)).result(binding)
      config = YAML.load(erb)
      config["index"].should eq 1
      config["node_id"].should eq "mssql_node_free_1"
      config["mbus"].should eq nats
    end
  end
end