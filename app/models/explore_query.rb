# Module for Explore Queries, inherits from WhitelabQuery
class ExploreQuery < ActiveRecord::Base
  include WhitelabQuery
  
  # Load Explore Query by id or, if not given, by user id and query parameters
  def self.get_current_query(page, user_id, listtype, params)
    # Find query by id
    if params.has_key?(:id)
      query = ExploreQuery.find(params[:id])
      if (params.has_key?(:patt) && !params[:patt].eql?(query.patt)) || (params.has_key?(:filter) && !params[:filter].eql?(query.filter))
        query = nil
      end
    end
    
    # If none is found, find query by patt and filter
    if !query && (params.has_key?(:patt) || (page.eql?('statistics') && params.has_key?(:filter)))
      query_params = ExploreQuery.add_default_params(page, user_id, params)
      query = ExploreQuery.joins(:query_result).where({
        :patt => query_params[:patt],
        :filter => query_params[:filter],
        :user_id => user_id
      }).order("query_results.status DESC, updated_at DESC").first
      # or create a new one
      if !query
        query = ExploreQuery.create(ExploreQuery.get_create_params(page, user_id, params))
      end
    end
    
    if query
      result_params = QueryResult.add_default_params('explore', query, params.except(:input_page, :view_page, :user_id, :id), listtype)
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
  
  # Get parameters to find ExploreQuery
  def self.add_default_params(page, user_id, params)
    new_params = params.except(:within, :group, :view, :offset, :number, :input_page, :patt, :filter)
    new_params[:patt] = params.has_key?(:patt) && !params[:patt].blank? ? params[:patt] : '[word=".*"]'
    new_params[:input_page] = params.has_key?(:input_page) ? params[:input_page] : page
    new_params[:user_id] = user_id
    new_params[:filter] = params.has_key?(:filter) && !params[:filter].blank? ? params[:filter] : nil
    return new_params
  end
  
  # Get parameters to create ExploreQuery
  def self.get_create_params(page, user_id, params)
    new_params = params.except(:within, :group, :view, :offset, :number, :view_page, :input_page, :patt)
    new_params[:patt] = params.has_key?(:patt) ? params[:patt] : '[word=".*"]'
    new_params[:user_id] = user_id
    new_params[:input_page] = params.has_key?(:input_page) ? params[:input_page] : page
    return new_params
  end
  
  def page
    self.input_page
  end
  
end
