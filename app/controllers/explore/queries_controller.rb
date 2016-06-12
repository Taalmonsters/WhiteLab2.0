class Explore::QueriesController < ApplicationController
  include WhitelabExplore
  before_action :set_limits_and_queries, :only => [:history]
  before_action :set_option
  before_action :set_grouping, :only => [:result]
  
  # Load bubble chart data for Explore Corpora interface
  def bubble
    @data = format_for_bubble_chart(@metadata_handler.get_filtered_group_composition(@option, @filter), @option, @filtered_total_abs)
    respond_to do |format|
      if @data['max_doc_count'] == 0
        @element = 'bubble-chart'
        @msg = {}
        @msg[:error] = "Failed to load bubble chart"
        format.js { render '/layouts/error' }
        format.json { render json: @msg }
        format.xml { render xml: @msg }
      else
        format.js
        format.json { render json: @data}
        format.xml { render xml: @data }
      end
    end
  end
  
  # Show Explore Query details
  def details
    respond_to do |format|
      format.js do
        render '/query/details'
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
      @export_query = Explore::Query.export(@query)
    end
    respond_to do |format|
      format.js do
        render '/query/export'
      end
    end
  end
  
  # Show Explore Query history
  def history
    respond_to do |format|
      format.js do
        render '/query/history'
      end
    end
  end
  
  # Remove Explore Query
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
  
  # Show Explore Query result
  def result
    respond_to do |format|
      format.js do
        render '/query/result'
      end
    end
  end
  
  # Load Explore Query result pagination
  def result_pagination
    respond_to do |format|
      format.js do
        render '/query/result_pagination'
      end
    end
  end
  
  # Load treemap data for Explore Corpora interface
  def treemap
    @data = format_for_treemap(@metadata_handler.get_filtered_group_composition(@option, @filter), @option, @filtered_total_abs)
    respond_to do |format|
      if @data['children'].size == 1 && @data['children'][0]['size'] == 0
        @element = 'display'
        @msg = {}
        @msg[:error] = "Failed to load treemap"
        format.js { render '/layouts/error' }
        format.json { render json: @msg }
        format.xml { render xml: @msg }
      else
        format.js
        format.json { render json: @data}
        format.xml { render xml: @data }
      end
    end
  end
  
  # Load vocabulary growth data for Explore Statistics interface
  def vocabulary_growth
#     TODO: This makes no sense
    if @query && (@query.blank? || (@query.result.blank? && (!@query.running? || !@query.finished?)))
      @document = { 'types' => [{ name: '', x: 0, y: 0 }], 'lemmas' => [{ name: '', x: 0, y: 0 }] }
      data = @whitelab.get_filtered_content(@query)
      types_seen = []
      t = 0
      lemmas_seen = []
      l = 0
      data['content'].each do |token|
        t = t + 1
        if !types_seen.include?(token['hit_text'])
          types_seen << token['hit_text']
        end
        l = l + 1
        if !lemmas_seen.include?(token['hit_lemma'])
          lemmas_seen << token['hit_lemma']
        end
        @document['types'] << { name: token['hit_text'], x: t, y: types_seen.size }
        @document['lemmas'] << { name: token['hit_lemma'], x: l, y: lemmas_seen.size }
      end
      @query.update_attribute(:result, { title: 'Vocabulary growth', data: [{ name: 'word_types', color: '#A90C28', data: @document['types'] }, { name: 'lemmas', color: '#53c4c3', data: @document['lemmas'] }] })
      @query.update_attribute(:status, 10)
    end
    render json: @query.result
  end
  
  protected
  
  # Get grouping options for grouped hits or documents, depending on selected view
  def set_grouping
    if @query
      view = @query.view
      group = @query.group
      if [8,16].include?(view)
        @groups = @metadata_handler.get_group_options(view, 'explore')
        if !group.blank?
          @group = group.gsub(/ /,"_")
        end
      end
    end
  end
  
  def set_option
    @option = params[:option] || 'Corpus_title'
  end
  
  def set_limits_and_queries
    @qllimit = params.has_key?(:qllimit) && !params[:qllimit].blank? ? params[:qllimit].to_i : 5
    @eqllimit = params.has_key?(:eqllimit) && !params[:eqllimit].blank? ? params[:eqllimit].to_i : 5
    @queries = @user.query_history('explore_queries', @qllimit)
    @export_queries = @user.query_history('export_queries', @eqllimit)
  end
  
end
