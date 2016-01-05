# Controller for data exports.
class DataController < ApplicationController
  include DataFormatHelper
  before_action :set_current_query, :only => [:export]
  
  # Start query export
  def export
    if !@query.blank?
      @export_query = ExportQuery.get_current_query(@user.id, @page, QueryResult.find(@query.query_result_id))
    end
    respond_to do |format|
      format.js do
        render '/query/export'
      end
    end
  end
  
  # Download query export
  def download_export
    @export_query = ExportQuery.find(params[:id])
    if @export_query
      data = []
      @export_query.query_results.sort_by { |x| x.offset }.each do |query_result|
        data.insert(query_result.offset, *query_result.result)
      end
      respond_to do |format|
        format.csv { send_data aoh_to_csv(data), :filename => @export_query.generate_filename+'.csv' }
        format.json { send_data data.to_json, :filename => @export_query.generate_filename+'.json' }
      end
    else
      respond_to do |format|
        format.csv { send_data nil, :filename => 'error.csv' }
        format.json { send_data 'Could not find export query' }
      end
    end
  end
  
  protected
  
  # Find query to be exported
  def set_current_query
    @namespace = 'search'
    if params[:namespace] && ['explore', 'search'].include?(params[:namespace])
      @namespace = params[:namespace]
    end
    if @namespace.eql?('search') && params[:id]
      @query = SearchQuery.find_by_id_and_user_id(params[:id], @user.id)
      p @query.to_json
    elsif @namespace.eql?('explore') && params[:id]
      @query = ExploreQuery.find(params[:id])
    end
  end
  
end