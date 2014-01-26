require 'rubygems'
require 'bundler/setup'

Bundler.require :default

require 'rspec/core/rake_task'
require 'puppetlabs_spec_helper/rake_tasks'

task :default do
  sh %{rake -T}
end

if RUBY_VERSION >= "1.9"
  # Generating API documentation, run with 'rake yard'
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.options =  ['-m','markdown']
  end
end
