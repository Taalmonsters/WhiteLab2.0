require 'singleton'

# The WhitelabBackend class is a wrapper for the backend helper classes and makes them available in a singleton
class WhitelabBackend
  include Singleton

  # Initialize the backend
  def initialize
    @backend_type = Rails.configuration.x.database_type
    load_modules
  end

  # Return the identifier from the backend
  def get_backend_type
    return @backend_type
  end
  
  private

  # Load the required modules
  def load_modules
    klass = self.class
    module_name = required_module_name
    klass.send(:include, module_name.constantize) unless klass.included_modules.map { |mod| mod.to_s }.include?(module_name)
  end

  # Return the required module name for the backend helper
  def required_module_name
    return 'BlacklabHelper'
  end
  
end