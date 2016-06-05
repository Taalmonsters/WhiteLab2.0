module WhitelabExplore
  extend ActiveSupport::Concern

  included do
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
  
end