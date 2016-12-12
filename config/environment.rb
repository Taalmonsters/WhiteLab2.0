# Load the Rails application.
require File.expand_path('../application', __FILE__)

Mime::Type.register "text/tsv", :tsv

# Initialize the Rails application.
Rails.application.initialize!