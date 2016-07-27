$stdout.sync = $stderr.sync = true
require_relative 'config/bootstrap'

Resque::Server.class_eval do
  use Rack::Auth::Basic, 'Restricted' do |username, password|
    [username, password] == [ENV['RESQUE_USER'], ENV['RESQUE_PASSWORD']]
  end
end

map('/jobs') { run Resque::Server.new }
map('/admin') { run AdminController }
map('/') { run ClientController }