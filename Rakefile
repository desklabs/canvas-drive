$stdout.sync = $stderr.sync = true

require 'rubygems'
require 'bundler/setup'
require 'resque/tasks'
require_relative 'config/bootstrap'

desc 'start a console in the current environment'
task :console do
  begin
    require 'pry'
    Pry.start binding, quiet: true
  rescue
    puts 'Looks like something is messed up!'
  end
end
