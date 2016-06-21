$stdout.sync = $stderr.sync = true

require 'json'
require 'base64'
require 'openssl'
require 'sinatra/base'
require 'active_model'
require 'active_support'
require 'excon'

Dir.glob('./{adapters,helpers,controllers}/**/*.rb').each { |file| require file }

map('/admin') { run AdminController }
map('/') { run ClientController }