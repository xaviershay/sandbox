require 'rspec/core/rake_task'

# Put spec opts in a file named .rspec in root

desc "Run acceptance specs"
RSpec::Core::RakeTask.new(:'spec:acceptance') do |t|
  t.pattern = "./spec/acceptance/**/*_spec.rb"
end

desc "Run unit specs"
RSpec::Core::RakeTask.new(:'spec:unit') do |t|
  t.pattern = "./spec/unit/**/*_spec.rb"
end

task :spec => [:'spec:unit', :'spec:acceptance']

desc 'Default: run specs.'
task :default => :spec
