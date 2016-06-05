# Interface controller for pages under Explore namespace
class Explore::InterfaceController < InterfaceController
  include WhitelabExplore
  before_action :set_page
  before_action :set_query
  before_action :set_document, :only => :document
  before_action :set_listtype_options, :only => [:statistics, :ngrams]
  
  # Redirect from /explore to /explore/corpora
  def explore
    redirect_to explore_corpora_path
  end
  
  def corpora
    @option = params[:option] || 'Corpus_title'
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
    @size = params[:size] || 5
    respond_to do |format|
      format.html
    end
  end
  
  def document
    respond_to do |format|
      flash[:error] = "Document '#{params[:xmlid]}' not found" if params.has_key?(:xmlid) && !params[:xmlid].blank? && !@document
      format.html
    end
  end
  
  protected
  
  # Get translated list type options
  def set_listtype_options
    @listtype = params[:listtype] || 'word'
    @listtype_options = []
    ['word', 'lemma', 'pos', 'phonetic'].each do |type|
      @listtype_options << [t(:"data_labels.keys.#{type}").capitalize, type]
    end
  end
  
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