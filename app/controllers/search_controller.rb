# Main controller for Search namespace.
class SearchController < ApplicationController
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
    @pos_heads = get_translated_pos_heads
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
      docpid = params[:docpid]
      @target = docpid
      @doc_hits = @whitelab.get_search_results_for_query(@query.query_result, docpid, nil, nil)["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/doc_hits'
      end
    end
  end
  
  # Load hits for Search Query in selected group
  def hits_in_group
    results_in_group(:hits_group)
    respond_to do |format|
      format.js do
        render '/result/hits_in_group'
      end
    end
  end
  
  # Load documents for Search Query in selected group
  def docs_in_group
    results_in_group(:docs_group)
    respond_to do |format|
      format.js do
        render '/result/docs_in_group'
      end
    end
  end
  
  # Load keywords in context for hit
  def kwic
    @target = get_target_from_params
    if @target
      @kwic = @whitelab.get_kwic(params[:docpid], params[:first_index], params[:last_index], params[:size])
    end
    respond_to do |format|
      format.js do
        render '/result/kwic'
      end
    end
  end
  
  protected
  
  def get_target_from_params
    docpid = params[:docpid] || ''
    first_index = params.has_key?(:first_index) ? params[:first_index].to_s : ''
    last_index = params.has_key?(:last_index) ? params[:last_index].to_s : ''
    return docpid+'_'+first_index+'_'+last_index if docpid && first_index && last_index
    nil
  end
  
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
        @query.query_result.execute_threaded("SEARCH QUERY CHANGED")
      end
    end
  end
  
  # Load Search Query history
  def load_query_list
    @qllimit, @queries = @user.query_history(params.has_key?(:qllimit) ? params[:qllimit].to_i : nil, 'search_queries')
  end
  
  # Get grouping options for grouped hits or documents, depending on selected view
  def set_grouping
    if @query
      qresult = @query.query_result
      if !qresult.blank?
        view = qresult.view
        group = qresult.group
        if [8,16].include?(view)
          @groups = @metadata_handler.get_group_options(view, 'search')
          if !group.blank?
            @group = group.gsub(/ /,"_")
          end
        end
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
  
  # Load hits or documents for Search Query in selected group
  def results_in_group(key)
    if @query && params.has_key?(:group_id) && params.has_key?(key)
      qresult = @query.query_result
      @offset = params[:offset] || 0
      @group = params[key]
      @group_id = params[:group_id]
      if key.eql?(:hits_group)
        @hits = @whitelab.get_hits_in_group(qresult,@group,@offset,20)['hits']
      else
        @docs = @whitelab.get_docs_in_group(qresult,@group,@offset,20)['docs']
      end
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