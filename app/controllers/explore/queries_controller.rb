class Explore::QueriesController < QueriesController
  include WhitelabExplore
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
  
end
