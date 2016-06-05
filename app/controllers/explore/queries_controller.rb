class Explore::QueriesController < ApplicationController
  before_action :set_option
  
  # Load treemap data for Explore Corpora interface
  def treemap
    @data = format_for_treemap(@metadata_handler.get_filtered_group_composition(@option, @filter), @option, @filtered_total_abs)
    respond_to do |format|
      if @data['size'].nil?
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
  
  # Load bubble chart data for Explore Corpora interface
  def bubble
    @data = format_for_bubble_chart(@metadata_handler.get_filtered_group_composition(@option, @filter), @option, @filtered_total_abs)
    p @data
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
  
  protected
  
  def set_option
    @option = params[:option] || 'Corpus_title'
  end
  
end
