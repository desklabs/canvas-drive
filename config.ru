$stdout.sync = $stderr.sync = true


require 'sinatra/base'
Dir.glob('./{adapters,helpers,controllers}/**/*.rb').each { |file| require file }

map('/admin') { run AdminController }
map('/') { run ClientController }