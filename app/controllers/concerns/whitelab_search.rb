module WhitelabSearch
  extend ActiveSupport::Concern

  included do
    before_filter :set_query
    before_filter :set_document
    before_filter :set_filter
    before_filter :set_filtered_amount
  end
  
  protected
  
  # Set current query
  def set_query
    @query = Search::Query.find_from_params(action_name, @user.id, query_create_params) if params.has_key?(:patt)
    @result = @query.execute if @query && !@query.finished? && !@query.failed?
  end
  
  # Set current document
  def set_document
    patt = params[:patt]
    patt = @user.search_queries.find(params[:id]).patt if !patt && params.has_key?(:id)
    @document = Document.new({ :xmlid => params[:xmlid], :patt => patt }) if params.has_key?(:xmlid)
    @document = nil if @document && @document.token_count.blank?
  end
  
  private
  
  # Check allowed parameters for query creation
  def query_create_params
    params.permit(:patt, :id, :within, :filter, :view, :group, :sort, :order, :offset, :number, :input_page)
  end
  
end