# Module for Search Queries, inherits from WhitelabQuery
class Search::Query < ActiveRecord::Base
  include WhitelabQuery
  
  def self.find_from_params(page, user_id, params)
    return WhitelabQuery.find_from_params(Search::Query, page, user_id, params)
  end
end
