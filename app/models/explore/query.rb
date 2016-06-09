# Module for Search Queries, inherits from WhitelabQuery
class Explore::Query < ActiveRecord::Base
  include WhitelabQuery
  
  def self.find_from_params(page, user_id, params)
    return WhitelabQuery.find_from_params(Explore::Query, page, user_id, params)
  end
end
