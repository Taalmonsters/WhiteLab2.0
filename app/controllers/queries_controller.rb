class QueriesController < ApplicationController
  before_action :set_limits_and_queries, :only => [:history]
  
  # Download Query export
  def download
    respond_to do |format|
      format.csv { send_file @query.result_file, :disposition=>"attachment; filename='#{@query.generate_filename}.csv'" }
      format.tsv { send_file @query.result_file(true), :disposition=>"attachment; filename='#{@query.generate_filename}.tsv'" }
      format.xml { send_file @query.metadata_file, :disposition=>"attachment; filename='#{@query.generate_filename}.xml'" }
    end
  end
  
  # Start Query export
  def export
    respond_to do |format|
      format.js do
        if !@query.blank?
          @query.export
        end
        render '/query/export'
      end
      format.xml do
        send_data(@query.to_xml, :type=>"text/xml",:filename => "#{@query.generate_filename}.xml")
      end
    end
  end
  
  # Show Query history
  def history
    respond_to do |format|
      format.js do
        render '/query/history'
      end
    end
  end
  
  # Remove Query
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
  
  # Show Query result
  def result
    respond_to do |format|
      format.js do
        render '/query/result'
      end
    end
  end
  
  # Load Query result pagination
  def result_pagination
    respond_to do |format|
      format.js do
        render '/query/result_pagination'
      end
    end
  end
  
  protected
  
  def set_limits_and_queries
    @sl = params.has_key?(:sl) && !params[:sl].blank? ? params[:sl].to_i : 5
    @el = params.has_key?(:el) && !params[:el].blank? ? params[:el].to_i : 5
    @search_queries = @user.query_history('search_queries', @sl)
    @explore_queries = @user.query_history('explore_queries', @el)
  end
  
end
