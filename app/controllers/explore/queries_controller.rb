class Explore::QueriesController < ApplicationController
  include WhitelabExplore
  before_action :set_option
  
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
      format.csv { send_data @export_query.result.to_csv }
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
  
  # Show Explore Query result
  def result
    @view = 8
    if @query && [8,16].include?(@query.query_result.view)
      @view = @query.query_result.view
      @groups = @metadata_handler.get_group_options(@query.query_result.view, 'explore')
      if !@query.query_result.group.blank?
        @group = @query.query_result.group.gsub(/ /,"_")
      end
    elsif @query
      @view = @query.query_result.view
    end
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
    if @query && (@query.query_result.blank? || (@query.query_result.result.blank? && (!@query.query_result.is_running || !@query.query_result.is_finished)))
      @document = { 'types' => [{ name: '', x: 0, y: 0 }], 'lemmas' => [{ name: '', x: 0, y: 0 }] }
      data = @whitelab.get_filtered_content(@query.query_result)
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
      @query.query_result.update_attribute(:result, { title: 'Vocabulary growth', data: [{ name: 'word_types', color: '#A90C28', data: @document['types'] }, { name: 'lemmas', color: '#53c4c3', data: @document['lemmas'] }] })
      @query.query_result.update_attribute(:status, 10)
    end
    render json: @query.query_result.result
  end
  
  protected
  
  def set_option
    @option = params[:option] || 'Corpus_title'
  end
  
end
