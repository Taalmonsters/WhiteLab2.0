# Main controller for Explore namespace.
class ExploreController < ApplicationController
  before_action :set_page, :only => [:corpora, :statistics, :ngrams, :document]
  before_action :set_treemap_option, :only => [:corpora, :treemap, :bubble]
  before_action :set_treemap_options, :only => [:corpora]
  before_action :set_tab, :only => [:document]
  before_action :set_xmlid, :only => [:document]
  before_action :set_list_type, :only => [:statistics, :ngrams]
  before_action :set_ngram_size, :only => [:ngrams]
  before_action :set_current_query, :only => [:statistics, :ngrams, :result, :result_pagination, :details, :vocabulary_growth, :export]
  before_action :set_filter, :only => [:corpora, :statistics, :ngrams, :treemap, :bubble, :vocabulary_growth]
  before_action :set_filtered_amount, :only => [:corpora, :statistics, :ngrams, :treemap, :bubble]
  before_action :load_query_list, :only => [:corpora, :statistics, :ngrams, :document, :history]
  before_action :load_export_query_list, :only => [:corpora, :statistics, :ngrams, :document, :history]
  before_action :set_listtype_options, :only => [:statistics, :ngrams]
  
  # Redirect from /explore to /explore/corpora
  def explore
    redirect_to explore_corpora_path
  end
  
  # Show Explore Corpora interface
  def corpora
    render 'explore/page'
  end
  
  # Load treemap data for Explore Corpora interface
  def treemap
    res = @metadata_handler.get_filtered_group_composition(@option, @filter)
    @data = format_for_treemap(res, @option, @filtered_total_abs)
  end
  
  # Load bubble chart data for Explore Corpora interface
  def bubble
    res = @metadata_handler.get_filtered_group_composition(@option, @filter)
    @data = format_for_bubble_chart(res, @option, @filtered_total_abs)
  end
  
  # Show Explore Statistics interface
  def statistics
    render 'explore/page'
  end
  
  # Show Explore N-grams interface
  def ngrams
    render 'explore/page'
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
  
  # Show Explore Document interface
  def document
    render 'explore/page'
  end
  
  # Show Explore Query details
  def details
    respond_to do |format|
      format.js do
        render '/query/details'
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
  
  # Start Explore Query export
  def export
    if !@query.blank?
      @export_query = ExploreQuery.export(@query)
    end
    respond_to do |format|
      format.js do
        render '/query/export'
      end
    end
  end
  
  # Download Explore Query export
  def download_export
    @export_query = ExportQuery.find(params[:id])
    respond_to do |format|
      format.csv { send_data @export_query.query_result.result.to_csv }
    end
  end
  
  protected
  
  # Set current page
  def set_page
    @page = action_name
  end
  
  # Set grouping option for treemap in explore/corpora
  def set_treemap_option
    if params.has_key?(:option)
      @option = params[:option]
    else
      @option = 'Corpus_title'
    end
  end
  
  # Get all grouping options for treemap in explore/corpora
  def set_treemap_options
    @options = @metadata_handler.get_group_options(16, 'explore')
  end
  
  # Get document id from parameters
  def set_xmlid
    @xmlid = nil
    if params.has_key?(:xmlid)
      @xmlid = params[:xmlid]
    end
  end
  
  # Get selected list type from parameters
  def set_list_type
    @listtype = 'word'
    if params.has_key?(:listtype)
      @listtype = params[:listtype]
    end
  end
  
  # Get selected n-gram size from parameters
  def set_ngram_size
    @size = 5
    if params.has_key?(:size)
      @size = params[:size].to_i
    end
  end
  
  # Get selected metadata filter from parameters
  def set_filter
    @filter = ''
    if @query && !@query.filter.blank?
      @filter = @query.filter
    elsif params[:filter] && !params[:filter].blank?
      @filter = params[:filter]
    end
  end
  
  # Get translated list type options
  def set_listtype_options
    @listtype_options = []
    ['word', 'lemma', 'pos', 'phonetic'].each do |type|
      @listtype_options << [t(:"data_labels.keys.#{type}").capitalize, type]
    end
  end
  
  # Load Explore Query history
  def load_query_list
    @qllimit, @queries = @user.query_history(params.has_key?(:qllimit) ? params[:qllimit].to_i : nil, 'explore_queries')
  end
  
  # Load current Explore Query
  def set_current_query
    @query = ExploreQuery.get_current_query(@page, @user.id, @listtype, query_create_params)
  end
  
  private
  
  # Check allowed parameters for query creation
  def query_create_params
    params.permit(:id, :patt, :filter, :within, :view, :group, :offset, :number, :input_page)
  end
  
  # Check allowed parameters for query update
  def query_update_params
    params.permit(:view, :sort, :order, :offset, :number, :input_page, :group)
  end
  
end