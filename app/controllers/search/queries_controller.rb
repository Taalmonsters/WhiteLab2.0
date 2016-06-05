class Search::QueriesController < ApplicationController
  include WhitelabSearch
  before_action :set_grouping, :only => [:result]
  
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
      @doc_hits = @whitelab.get_search_results_for_query(@query, @target, nil, nil)["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/doc_hits'
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
  
  # Load hits for Search Query in selected group
  def hits_in_group
    results_in_group(:hits_group)
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
  
  protected
  
  # Get grouping options for grouped hits or documents, depending on selected view
  def set_grouping
    if @query
      view = @query.view
      group = @query.group
      if [8,16].include?(view)
        @groups = @metadata_handler.get_group_options(view, 'search')
        if !group.blank?
          @group = group.gsub(/ /,"_")
        end
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
  
  # Load hits or documents for Search Query in selected group
  def results_in_group(key)
    if @query && params.has_key?(:group_id) && params.has_key?(key)
      @offset = params[:offset] || 0
      @group = params[key]
      @group_id = params[:group_id]
      if key.eql?(:hits_group)
        @hits = @whitelab.get_hits_in_group(@query,@group,@offset,20)['hits']
      else
        @docs = @whitelab.get_docs_in_group(@query,@group,@offset,20)['docs']
      end
    end
  end
  
end
