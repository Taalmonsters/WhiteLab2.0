# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks
require 'sdoc'

Rake::RDocTask.new("public_api") do |rdoc|
  rdoc.title = "WhiteLab #{File.read(Rails.root.join("VERSION.txt"))}"
  rdoc.rdoc_dir = 'public/doc/api'
  rdoc.options << '--fmt' << 'shtml'
  
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.rdoc_files.include('app/**/*.rb')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Rake::RDocTask.new("private_api") do |rdoc|
  rdoc.title = "WhiteLab #{File.read(Rails.root.join("VERSION.txt"))}"
  rdoc.rdoc_dir = 'doc/api'
  rdoc.options << '--fmt' << 'shtml'
  
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.rdoc_files.include('app/**/*.rb')
  rdoc.rdoc_files.include('lib/**/*.rb')
end