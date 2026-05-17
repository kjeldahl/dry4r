# frozen_string_literal: true

require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:lint)

desc "Run rspec with SimpleCov coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task["spec"].invoke
end

desc "Run crap4r against lib/ using existing SimpleCov data"
task crap: :coverage do
  require "rubygems"
  begin
    gem "crap4r"
  rescue Gem::LoadError
    abort "crap4r is not installed. Add it to your Gemfile or `gem install crap4r`."
  end
  sh "bundle exec crap4r --no-run lib"
end

desc "Run mutant against the Dry4r namespace"
task :mutant do
  sh "bundle exec mutant run --include lib --require dry4r --use rspec 'Dry4r*'"
end

task default: %i[lint spec]
