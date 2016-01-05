# Module for Search Queries, inherits from WhitelabQuery
class SearchQuery < ActiveRecord::Base
  include WhitelabQuery
  
  # Load Search Query by id or, if not given, by user id and query parameters
  def self.get_current_query(page, user_id, params)
    if params.has_key?(:id)
      query = SearchQuery.find_by_id_and_user_id(params[:id],user_id)
      if (params.has_key?(:patt) && !params[:patt].eql?(query.patt)) || (params.has_key?(:filter) && !params[:filter].eql?(query.filter))
        query = nil
      end
    end
    
    if !query && params.has_key?(:patt)
      query_params = SearchQuery.add_default_params(page, user_id, params)
      query = SearchQuery.where({
        :patt => query_params[:patt],
        :filter => query_params[:filter],
        :user_id => user_id
      }).order("updated_at DESC").first
      if !query
        query = SearchQuery.create(SearchQuery.get_create_params(page, user_id, params))
      end
    end
    
    if query
      result_params = QueryResult.add_default_params('search', query, params.except(:input_page, :view_page, :user_id, :id), nil)
      if query.query_result.blank? || query.query_result.is_updated(params, false)
        query.query_result = QueryResult.get_current_query_result(result_params)
        query.save
        if query.query_result.is_updated(params, true)
          query.query_result.update_attribute(:group_count, nil)
        end
      end
    end
    return query
  end
  
  # Get parameters to find SearchQuery
  def self.add_default_params(page, user_id, params)
    new_params = params.except(:within, :group, :view, :offset, :number, :view_page, :input_page, :filter)
    new_params[:input_page] = params.has_key?(:input_page) ? params[:input_page] : page
    new_params[:user_id] = user_id
    new_params[:view_page] = params.has_key?(:view_page) ? params[:view_page] : params[:input_page]
    new_params[:filter] = params.has_key?(:filter) && !params[:filter].blank? ? params[:filter] : ''
    return new_params
  end
  
  # Get parameters to create SearchQuery
  def self.get_create_params(page, user_id, params)
    new_params = params.except(:within, :group, :view, :offset, :number, :view_page, :input_page)
    new_params[:input_page] = params.has_key?(:input_page) ? params[:input_page] : page
    new_params[:user_id] = user_id
    new_params[:view_page] = params.has_key?(:view_page) ? params[:view_page] : params[:input_page]
    return new_params
  end
  
  def page
    self.view_page || self.input_page
  end
  
end
