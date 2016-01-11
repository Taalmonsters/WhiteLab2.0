require 'singleton'

class WhitelabBackend
  include Singleton
  @@BACKEND_TYPE = Rails.configuration.x.database_type
  
  def initialize
    mods = self.class.included_modules.map { |x| x.to_s }
    if @@BACKEND_TYPE.eql?('neo4j') && !mods.include?('Neo4jHelper') && !mods.include?('BlacklabHelper')
      self.class.send(:include, Neo4jHelper)
    elsif @@BACKEND_TYPE.eql?('blacklab') && !mods.include?('Neo4jHelper') && !mods.include?('BlacklabHelper')
      self.class.send(:include, BlacklabHelper)
    else
      abort("Unrecognized database type: "+@@BACKEND_TYPE.to_s)
    end
  end
  
  def get_backend_type
    return @@BACKEND_TYPE
  end
  
end