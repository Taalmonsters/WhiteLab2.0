# Main controller for Search namespace.
class SearchController < ApplicationController
  include DatabaseHelper
  before_action :set_search_namespace
  before_action :set_page, :only => [:simple, :extended, :advanced, :expert, :document]
  before_action :set_tab, :only => [:document]
  before_action :set_xmlid, :only => [:document]
  before_action :set_filter, :only => [:extended, :advanced, :expert]
  before_action :set_filtered_amount, :only => [:extended, :advanced, :expert]
  before_action :set_current_query, :only => [:simple, :extended, :advanced, :expert, :document, :result, :result_pagination, :history, :details, :doc_hits, :hits_in_group, :docs_in_group, :remove]
  before_action :load_query_list, :only => [:simple, :extended, :advanced, :expert, :history]
  before_action :load_export_query_list, :only => [:simple, :extended, :advanced, :expert, :history]
  before_action :set_grouping, :only => [:result]
  before_action :set_urls, :only => [:simple, :extended, :advanced, :expert, :document, :result]
  
  # Redirect from /search to /explore/expert (with CQL query) or /search/simple (without CQL query)
  def search
    if params.has_key?(:patt)
      redirect_to expert_search_path, :params => params
    else
      redirect_to simple_search_path
    end
  end
  
  # Show Search Simple interface
  def simple
    render 'search/page'
  end
  
  # Show Search Extended interface
  def extended
    render 'search/page'
  end
  
  # Show Search Advanced interface
  def advanced
    render 'search/page'
  end
  
  # Show Search Expert interface
  def expert
    render 'search/page'
  end
  
  # Show Search Document interface
  def document
    render 'search/page'
  end
  
  # Show Search Query details
  def details
    respond_to do |format|
      format.js do
        render '/query/details'
      end
    end
  end
  
  # Show Search Query history
  def history
    respond_to do |format|
      format.js do
        render '/query/history'
      end
    end
  end
  
  # Show Search Query result
  def result
    respond_to do |format|
      format.js do
        render '/query/result'
      end
    end
  end
  
  # Load Search Query result pagination
  def result_pagination
    respond_to do |format|
      format.js do
        render '/query/result_pagination'
      end
    end
  end
  
  # Remove Search Query
  def remove
    if !@query.blank?
      @query_id = @query.id
      @query.destroy
    end
    respond_to do |format|
      format.js do
        render '/query/remove'
      end
    end
  end
  
  # Load hits for Search Query in selected document
  def doc_hits
    if @query && params.has_key?(:docpid)
      @target = params[:docpid]
      @doc_hits = get_search_results_for_query(@query.query_result, params[:docpid], nil, nil)["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/doc_hits'
      end
    end
  end
  
  # Load hits for Search Query in selected group
  def hits_in_group
    if @query && params.has_key?(:group_id) && params.has_key?(:hits_group)
      @offset = params[:offset] || 0
      @group = params[:hits_group]
      @group_id = params[:group_id]
      @hits = get_hits_in_group(@query.query_result,@group,@offset,20)['hits']
    # elsif params.has_key?(:hits_group)
      # TODO: new query from group or redirect to search page with new query params
    end
    respond_to do |format|
      format.js do
        render '/result/hits_in_group'
      end
    end
  end
  
  # Load documents for Search Query in selected group
  def docs_in_group
    if @query && params.has_key?(:group_id) && params.has_key?(:docs_group)
      @offset = params[:offset] || 0
      @group = params[:docs_group]
      @group_id = params[:group_id]
      @docs = get_docs_in_group(@query.query_result,@group,@offset,20)['docs']
    # elsif params.has_key?(:docs_group)
      # TODO: new query from group or redirect to search page with new query params
    end
    respond_to do |format|
      format.js do
        render '/result/docs_in_group'
      end
    end
  end
  
  # Load keywords in context for hit
  def kwic
    if params.has_key?(:docpid) && params.has_key?(:first_index) && params.has_key?(:last_index) && params.has_key?(:size)
      @target = params[:docpid]+'_'+params[:first_index].to_s+'_'+params[:last_index].to_s
      @kwic = get_kwic(params[:docpid], params[:first_index], params[:last_index], params[:size])
    end
    respond_to do |format|
      format.js do
        render '/result/kwic'
      end
    end
  end
  
  protected
  
  # Set namespace to 'search'
  def set_search_namespace
    @namespace = 'search'
  end
  
  # Set current page
  def set_page
    if params.has_key?(:page)
      @page = params[:page]
    else
      @page = action_name
    end
  end
  
  # Set current tab
  def set_tab
    @tab = 'content'
    if params.has_key?(:tab) && !params[:tab].blank?
      @tab = params[:tab]
    end
  end
  
  # Get document id from parameters
  def set_xmlid
    @xmlid = nil
    if params.has_key?(:xmlid)
      @xmlid = params[:xmlid]
    end
  end
  
  # Get selected metadata filter from Search Query
  def set_filter
    @filter = ''
    if @query
      @filter = @query.filter
    end
  end
  
  # Load current Search Query
  def set_current_query
    @query = SearchQuery.get_current_query(@page, @user.id, query_create_params(params))
  end
  
  # Update current Search Query
  def update_query
    if @query && @query.has_changed(params)
      if @query.update_attributes(query_update_params)
        @query.execute(true, "SEARCH QUERY CHANGED")
      end
    end
  end
  
  # Load Search Query history
  def load_query_list
    @qllimit = 5
    if params[:qllimit]
      @qllimit = params[:qllimit].to_i
    end
    @queries = SearchQuery.where(:user_id => @user.id).order("updated_at DESC").limit(@qllimit)
    @has_more_queries = SearchQuery.where(:user_id => @user.id).count('id', :distinct => true) > @qllimit
    @has_unfinished_queries = false
    @queries.each do |query|
      if query.query_result.blank? || !query.query_result.is_finished
        @has_unfinished_queries = true
        break
      end
    end
  end
  
  # Load Export Query history
  def load_export_query_list
    @eqllimit = 5
    if params[:eqllimit]
      @eqllimit = params[:eqllimit].to_i
    end
    @export_queries = ExportQuery.where(:user_id => @user.id).order("created_at DESC").limit(@eqllimit)
    @has_more_export_queries = ExportQuery.where(:user_id => @user.id).count('id', :distinct => true) > @eqllimit
    @has_unfinished_export_queries = false
    @export_queries.each do |query|
      if query.status == 0 || query.status == 1
        @has_unfinished_export_queries = true
        break
      end
    end
  end
  
  # Get grouping options for grouped hits or documents, depending on selected view
  def set_grouping
    if @query && !@query.query_result.blank? && [8,16].include?(@query.query_result.view)
      @groups = get_group_options(@query.query_result.view)
      if !@query.query_result.group.blank?
        @group = @query.query_result.group.gsub(/ /,"_")
      end
    end
  end
  
  # Set base URL and parameters for links in result displays
  def set_urls
    @query_base_url = ''
    @query_params = ''
    if !@query.blank?
      @query_base_url = '/search/'+@query.page+'?'+@query.assemble_url_params(['patt', 'filter', 'within'])
      @query_params = '?'+@query.assemble_url_params(['patt', 'filter', 'within', 'view', 'group', 'number', 'offset'])
    end
  end
  
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