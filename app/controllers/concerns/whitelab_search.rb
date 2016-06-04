module WhitelabSearch
  extend ActiveSupport::Concern

  included do
    before_filter :set_document
  end
  
  protected
  
  # Set current document
  def set_document
    patt = params[:patt]
    patt = @user.search_queries.find(params[:id]).patt if !patt && params.has_key?(:id)
    @document = Document.new({ :xmlid => params[:xmlid], :patt => patt }) if params.has_key?(:xmlid)
    @document = nil if @document && @document.token_count.blank?
  end
  
end