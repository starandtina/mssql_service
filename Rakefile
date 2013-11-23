require "rspec/core/rake_task"

namespace :spec do
  RSpec::Core::RakeTask.new :unit do |t|
    t.pattern = FileList['spec/unit/**/*_spec.rb']
    t.rspec_opts = "--color --format documentation --profile"
  end

  RSpec::Core::RakeTask.new :functional do |t|
    t.pattern = FileList['spec/functional/**/*_spec.rb']
    t.rspec_opts = "--color --format documentation --profile"
  end
end
