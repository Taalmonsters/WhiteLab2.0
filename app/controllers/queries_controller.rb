# Controller for query related requests.
class QueriesController < ApplicationController
  before_action :set_limits_and_queries, :only => [:history]
  
  # Download query result export
  def download
    respond_to do |format|
      format.csv { send_file @query.result_file, :disposition=>"attachment; filename='#{@query.generate_filename}.csv'" }
      format.tsv { send_file @query.result_file(true), :disposition=>"attachment; filename='#{@query.generate_filename}.tsv'" }
      format.xml { send_file @query.metadata_file, :disposition=>"attachment; filename='#{@query.generate_filename}.xml'" }
    end
  end
  
  # Start query export. If the selected output format is Javascript (.js), then the query results are exported and an alert is shown to the user.
  # If the output format is XML (.xml), then the query definition is generated and immediately sent to the user for download.
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
  
  # Show query history
  def history
    respond_to do |format|
      format.js do
        render '/query/history'
      end
    end
  end
  
  # Remove query from the query history
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
  
  # Show query result
  def result
    respond_to do |format|
      format.js do
        render '/query/result'
      end
    end
  end
  
  # Load query result pagination
  def result_pagination
    respond_to do |format|
      format.js do
        render '/query/result_pagination'
      end
    end
  end
  
  protected

  # Set the limits for listing queries in the query history table
  def set_limits_and_queries
    @sl = params.has_key?(:sl) && !params[:sl].blank? ? params[:sl].to_i : 5
    @el = params.has_key?(:el) && !params[:el].blank? ? params[:el].to_i : 5
    @search_queries = @user.query_history('search_queries', @sl)
    @explore_queries = @user.query_history('explore_queries', @el)
  end
  
end
