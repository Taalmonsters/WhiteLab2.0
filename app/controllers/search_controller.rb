# Main controller for Search namespace.
class SearchController < ApplicationController
  
  protected
  
  private
  
  # Check allowed parameters for query creation
  def query_create_params(params)
    params.permit(:patt, :id, :within, :filter, :view, :group, :sort, :order, :offset, :number, :input_page, :view_page)
  end
  
  # Check allowed parameters for query update
  def query_update_params
    params.permit(:view, :group, :sort, :order, :offset, :number, :view_page, :group)
  end
  
end