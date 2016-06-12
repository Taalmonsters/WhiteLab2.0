class Search::QueriesController < ApplicationController
  include WhitelabSearch
  before_action :set_limits_and_queries, :only => [:history]
  
  # Show Search Query details
  def details
    respond_to do |format|
      format.js do
        render '/query/details'
      end
    end
  end
  
  # Load hits for Search Query in selected document
  def doc_hits
    if @query && params.has_key?(:docpid)
      @target = params[:docpid]
      @query.view = 1
      @query.filter = @query.filter.blank? ? "(id:#{@target})" : "#{@query.filter}AND(id:#{@target})"
      @query.offset = 0
      @query.number = params[:hits]
      @doc_hits = @query.result["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/doc_hits'
      end
    end
  end
  
  # Load documents for Search Query in selected group
  def docs_in_group
    @group_id = params[:group_id]
    if @query
      @query = @query.clone
      @query.filter = @query.filter.blank? ? "("+@query.group+"=\""+params[:docs_group]+"\")" : @query.filter+"AND("+@query.group+"=\""+params[:docs_group]+"\")"
      @query.view = 2
      @query.group = nil
      @query.offset = params[:offset] || 0
      @query.number = 20
      @docs = @query.result["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/docs_in_group'
      end
    end
  end
  
  # Download Explore Query export
  def download_export
    @export_query = @user.export_queries.find(params[:id])
    respond_to do |format|
      format.csv { send_data @export_query.result['results'].to_csv }
    end
  end
  
  # Start Explore Query export
  def export
    if !@query.blank?
      @export_query = Search::Query.export(@query)
    end
    respond_to do |format|
      format.js do
        render '/query/export'
      end
    end
  end
  
  # Load hits for Search Query in selected group
  def hits_in_group
    @group_id = params[:group_id]
    if @query
      @query = @query.clone
      @query.add_hits_group(params[:hits_group])
      @query.view = 1
      @query.group = nil
      @query.offset = params[:offset] || 0
      @query.number = 20
      @hits = @query.result["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/hits_in_group'
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
  
  private
  
  def get_target_from_params
    docpid = params[:docpid] || ''
    first_index = params.has_key?(:first_index) ? params[:first_index].to_s : ''
    last_index = params.has_key?(:last_index) ? params[:last_index].to_s : ''
    return docpid+'_'+first_index+'_'+last_index if docpid && first_index && last_index
    return nil
  end
  
  def set_limits_and_queries
    @qllimit = params.has_key?(:qllimit) && !params[:qllimit].blank? ? params[:qllimit].to_i : 5
    @eqllimit = params.has_key?(:eqllimit) && !params[:eqllimit].blank? ? params[:eqllimit].to_i : 5
    @queries = @user.query_history('search_queries', @qllimit)
    @export_queries = @user.query_history('export_queries', @eqllimit)
  end
  
end
