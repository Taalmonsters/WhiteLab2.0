# Module for Explore Queries, includes WhitelabQuery
class Explore::Query < ActiveRecord::Base
  include WhitelabQuery
  
  def self.find_from_params(page, user, params)
    query = user.explore_queries.find(params[:id].to_i) if params.has_key?(:id)
    return query ? query : WhitelabQuery.find_from_params(Explore::Query, page, user.id, params)
  end
  
  def self.create_hash(user_id, page, params)
    return {
      :user_id => user_id, 
      :patt => params[:patt].nil? || params[:patt].blank? ? "[#{params[:listtype] || 'word'}=\".*\"]" : params[:patt], 
      :within => params.has_key?(:within) ? params[:within] : 'document', 
      :filter => params.has_key?(:filter) ? params[:filter] : nil, 
      :listtype => params.has_key?(:listtype) ? params[:listtype] : 'word', 
      :ngram_size => params.has_key?(:size) ? params[:size] : nil, 
      :input_page => page,
      :status => 0
    }
  end
  
  def self.where_data(user_id, page, params)
    clause = []
    vals = []
    clause << "user_id = ?"
    vals << user_id
    clause << "BINARY patt = ?"
    vals << params.has_key?(:patt) && !params[:patt].blank? ? params[:patt] : "[#{params[:listtype] || 'word'}=\".*\"]"
    clause << "within = ?"
    vals << params.has_key?(:within) ? params[:within] : 'document'
    clause << "BINARY filter = ?"
    vals << params[:filter]
    clause << "listtype = ?"
    vals << params.has_key?(:listtype) ? params[:listtype] : 'word'
    clause << "ngram_size = ?"
    vals << params[:size]
    clause << "input_page = ?"
    vals << page
    return [clause.join(" AND "), vals].flatten
  end
  
  def is_changed?(page, params)
    return true if attribute_is_changed?(patt,params.has_key?(:patt) && !params[:patt].blank? ? params[:patt] : "[#{params[:listtype] || 'word'}=\".*\"]")
    return true if attribute_is_changed?(within,params.has_key?(:within) ? params[:within] : 'document')
    return true if attribute_is_changed?(filter,params[:filter])
    return true if attribute_is_changed?(listtype,params.has_key?(:listtype) ? params[:listtype] : 'word')
    return true if attribute_is_changed?(ngram_size,params[:size])
    return true if attribute_is_changed?(input_page,page)
    return false
  end
  
  def update_from_params(params)
    self.waiting! if self.failed?
    if attribute_is_changed?(view,params[:view])
      self.update_attributes({ :view => params[:view], :group => nil, :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    elsif attribute_is_changed?(group,params[:group])
      self.update_attributes({ :group => params[:group], :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    else
      changed = attributes_are_changed?(params.slice(:order, :sort, :number, :offset))
      if changed
        self.waiting!
        order = params[:order] if attribute_is_changed?(order,params[:order])
        sort = params[:sort] if attribute_is_changed?(sort,params[:sort])
        number = params[:number] if attribute_is_changed?(number,params[:number])
        offset = params[:offset] if attribute_is_changed?(offset,params[:offset])
        self.save!
      end
    end
    return self
  end
  
end
