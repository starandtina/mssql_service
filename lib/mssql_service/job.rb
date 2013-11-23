require "bundler/setup"

module VCAP
  module Services
    module MSSQL
    end
  end
end

require_relative "job/mssql_backup"