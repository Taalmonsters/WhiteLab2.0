module WhitelabExplore
  extend ActiveSupport::Concern

  included do
    before_filter :set_query
    before_filter :set_document
    before_filter :set_filter
    before_filter :set_filtered_amount
  end
  
  protected
  
  # Set current document
  def set_document
    @document = Document.new({ :xmlid => params[:xmlid] }) if params.has_key?(:xmlid)
    @document = nil if @document && @document.token_count.blank?
  end
  
  # Set current query
  def set_query
    if params.has_key?(:filter) || params.has_key?(:patt) || params.has_key?(:id)
      if params.has_key?(:filter) && (!params.has_key?(:view) || params[:view].to_i == 8)
        params[:group] = "hit:#{params[:listtype]}" if params.has_key?(:listtype) && ['word','pos','lemma'].include?(params[:listtype])
        
      end
      @query = Explore::Query.find_from_params(action_name, @user, query_create_params)
      @result = @query.execute if @query && !@query.finished? && !@query.failed?
    end
  end
  
  private
  
  # Check allowed parameters for query creation
  def query_create_params
    params.permit(:patt, :id, :within, :filter, :view, :listtype, :size, :group, :sort, :order, :offset, :number, :input_page)
  end
  
end