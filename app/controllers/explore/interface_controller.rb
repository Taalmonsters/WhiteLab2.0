# Interface controller for pages under Explore namespace
class Explore::InterfaceController < InterfaceController
  include Explore
  before_action :set_page
  before_action :set_query
  before_action :set_document, :only => :document
  
  # Redirect from /explore to /explore/corpora
  def explore
    redirect_to explore_corpora_path
  end
  
  def corpora
    respond_to do |format|
      format.html
    end
  end
  
  def statistics
    respond_to do |format|
      format.html
    end
  end
  
  def ngrams
    respond_to do |format|
      format.html
    end
  end
  
  def document
    respond_to do |format|
      flash[:error] = "Document not found" if params.has_key?(:xmlid) && !params[:xmlid].blank? && !@document
      format.html
    end
  end
  
  protected
  
  # Set current page
  def set_page
    @page = action_name
  end
  
  # Set current query
  def set_query
    @query = Explore::Query.find_from_params(@page, @user.id, params) if params.has_key?(:patt)
    @result = @query.execute if @query && !@query.finished? && !@query.failed?
  end
end