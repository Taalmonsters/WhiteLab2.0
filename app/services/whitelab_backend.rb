require 'singleton'

# The WhitelabBackend class is a wrapper for the backend helper classes and makes them available in a singleton
class WhitelabBackend
  include Singleton
  include MetadataHelper
  
  def initialize
    @backend_type = Rails.configuration.x.database_type
    load_modules
  end
  
  def get_backend_type
    return @backend_type
  end
  
  private
  
  def load_modules
    klass = self.class
    module_name = required_module_name
    klass.send(:include, module_name.constantize) unless klass.included_modules.map { |mod| mod.to_s }.include?(module_name)
  end
  
  def required_module_name
    @backend_type.eql?('blacklab') ? 'BlacklabHelper' : 'Neo4jHelper'
  end
  
end