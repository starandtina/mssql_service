require_relative "../spec_helper"

describe VCAP::Services::MSSQL::Node do
  before do
    VCAP::Services::MSSQL::Node.any_instance.stub(:initialize)
  end

  describe "#get_host" do
    context "when the mssql option provided host is localhost" do
      before do
        subject.instance_variable_set(:@local_ip, "base_ip")
        subject.instance_variable_set(:@mssql_configs, {
          "MSSQLSERVER2008R2" => {
            "host" => "localhost"
          }
        })
      end

      it "returns the IP of this machine" do
        subject.get_host.should == "base_ip"
      end
    end
  end
end