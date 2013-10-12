#source "http://rubygems.org"
source "http://ruby.taobao.org"

gem "nats"
gem "datamapper", ">= 0.10.2"
gem "do_sqlite3", :require => nil
gem "dm-sqlite-adapter"
gem 'eventmachine'
gem "em-http-request"
gem "json"
gem "mysql2", "~> 0.3.11"
gem "uuidtools"
gem "ruby-hmac", :require => "hmac-sha1"
gem "thin"
gem "sinatra"
gem "rake"
gem "curb"
gem 'vcap_common', :require => ['vcap/common', 'vcap/component'], :git => 'https://github.com/cloudfoundry/vcap-common.git'
gem 'vcap_logging', :require => ['vcap/logging'], :git => 'https://github.com/cloudfoundry/common.git', :ref => 'b96ec1192'
gem 'vcap_services_base', :git => 'https://github.com/cloudfoundry/vcap-services-base.git', branch: 'master'

group :test do
  gem 'activesupport', '~> 3.2'
  gem 'sequel'
  gem "rspec"
  gem "ci_reporter"
end
