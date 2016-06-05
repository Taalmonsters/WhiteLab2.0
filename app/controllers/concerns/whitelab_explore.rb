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
    if ['ngrams','statistics'].include?(action_name)
      @query = Explore::Query.find_from_params(action_name, @user.id, query_create_params) if params.has_key?(:patt)
      @result = @query.execute if @query && !@query.finished? && !@query.failed?
    end
  end
  
end