# Module for users, identified by HTTP_REMOTE_USER or IP
class User < ActiveRecord::Base
  has_many :search_queries, :class_name => Search::Query
  has_many :explore_queries, :class_name => Explore::Query
  
  # Load query history
  def query_history(query_method, ql = 5)
    return self.send(query_method).order("updated_at DESC").limit(ql)
  end

  # Check whether the current user has executed any queries
  def has_queries?
    self.search_queries.any? || self.explore_queries.any?
  end
  
  # Check if user has unfinished explore queries
  def has_unfinished_explore_queries?(limit = 0)
    limit > 0 ? self.explore_queries.where("status = ? OR status = ?", 0, 1).order("updated_at DESC").limit(limit).any? : self.explore_queries.where("status = ? OR status = ?", 0, 1).any?
  end
  
  # Check if user has unfinished search queries
  def has_unfinished_search_queries?(limit = 0)
    limit > 0 ? self.search_queries.where("status = ? OR status = ?", 0, 1).order("updated_at DESC").limit(limit).any? : self.search_queries.where("status = ? OR status = ?", 0, 1).any?
  end
  
end
