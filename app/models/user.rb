# Module for users, identified by HTTP_REMOTE_USER or IP
class User < ActiveRecord::Base
  has_many :search_queries
  has_many :explore_queries
  has_many :export_queries
  
  # Load query history
  def query_history(limit, query_method)
    ql = limit || 5
    return ql, self.send(query_method).order("created_at DESC").limit(ql)
  end
  
  def has_unfinished_explore_queries?(limit = 0)
    limit > 0 ? self.explore_queries.where("status = ? OR status = ?", 0, 1).order("created_at DESC").limit(limit).any? : self.explore_queries.where("status = ? OR status = ?", 0, 1).any?
  end
  
  def has_unfinished_export_queries?(limit = 0)
    limit > 0 ? self.export_queries.where("status = ? OR status = ?", 0, 1).order("created_at DESC").limit(limit).any? : self.export_queries.where("status = ? OR status = ?", 0, 1).any?
  end
  
  def has_unfinished_search_queries?(limit = 0)
    limit > 0 ? self.search_queries.where("status = ? OR status = ?", 0, 1).order("created_at DESC").limit(limit).any? : self.search_queries.where("status = ? OR status = ?", 0, 1).any?
  end
  
end
