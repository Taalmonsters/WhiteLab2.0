# Module for users, identified by HTTP_REMOTE_USER or IP
class User < ActiveRecord::Base
  has_many :search_queries
end
