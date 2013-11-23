source "http://rubygems.org"

gem "nats", "0.4.26"
gem "datamapper", "1.2.0"
gem "do_sqlite3", :require => nil
gem "dm-sqlite-adapter", "1.2.0"
gem 'eventmachine', "1.0.3"
gem "em-http-request", "1.1.1"
gem "json", "1.8.1"
gem "uuidtools", "2.1.4"
gem "rake", "10.1.0"
gem "thor", "0.18.1"
gem 'vcap_common', :require => ['vcap/common', 'vcap/component'], :git => 'https://github.com/cloudfoundry/vcap-common.git', :branch => 'master'
gem "vcap_services_base", :git => "https://github.com/vchs/vcap-services-base.git", branch: "steno"
gem 'vcap_services_messages', :git => 'https://github.com/vchs/vcap-services-messages.git', :branch => 'master'

if RUBY_PLATFORM=~ /mswin|mingw|cygwin/
  gem "win32-eventlog", "0.5.3"
  gem "win32-service", "0.8.2"
  gem "win32-process", "0.7.4"
  gem "sys-proctable", "0.9.3"
end

group :test do
  gem "rspec", "2.14.1"
  gem "tiny_tds", "0.6.1"
  gem "ci_reporter", "1.9.0"
end
