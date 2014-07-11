require 'rubygems'
require 'app'

if Sinatra::Base.production?
  require 'rake'
  Rake.load_rakefile("./Rakefile")
  Rake::Task['bower:install'].invoke
end

run ScuttleServer::App