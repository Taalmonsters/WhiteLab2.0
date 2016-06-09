class Export::QueriesController < ApplicationController
  before_action :set_query, :only => [:export]
  before_action :set_export_query
  
  # Start query export
  def export
    respond_to do |format|
      format.js do
        render '/query/export'
      end
    end
  end
  
  def download
    
  end
  
  protected
  
  def set_query
    namespace = params[:namespace] || 'search'
    @query = @user.send("#{namespace}_queries").find(params[:id])
  end
  
  def set_export_query
    if @query
      @export_query = Export::Query.from_query(@query, EXPORT_LIMIT)
      @user.export_queries << @export_query
    elsif params.has_key?(:id)
      @export_query = @user.export_queries.find(params[:id])
    end
  end
  
end