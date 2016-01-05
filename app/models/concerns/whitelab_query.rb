# Base module for Search and Explore queries
module WhitelabQuery
  extend ActiveSupport::Concern
  include DatabaseHelper

  included do
    belongs_to :user
    belongs_to :query_result
  end
  
  # Create URL parameter string for query with selected properties
  def assemble_url_params(only)
    prms = []
    self.query_result.attributes.each do |name, value|
      if only.include?(name)
        prms << name+'='+value.to_s
      end
    end
    prms.join('&')
  end
  
end