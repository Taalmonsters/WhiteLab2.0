# Module for Search Queries, inherits from WhitelabQuery
class Search::Query < ActiveRecord::Base
  include WhitelabQuery
end
