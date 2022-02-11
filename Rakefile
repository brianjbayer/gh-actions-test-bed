# frozen_string_literal: true

require 'bundler/audit/task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# Add Gem Tasks
Bundler::Audit::Task.new
RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

# Custom Tasks
desc 'Run rubocop and bundler-audit'
task :checks do
  Rake::Task['rubocop'].invoke
  Rake::Task['bundle:audit'].invoke
end

task default: :spec
