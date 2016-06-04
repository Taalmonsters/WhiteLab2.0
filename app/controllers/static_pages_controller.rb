# Controller for all static public pages.
class StaticPagesController < ApplicationController
  before_action :set_main_namespace
  
  # Load info page
  def info
    @tab = 'info'
  end
  
  # Set namespace to 'main'
  def set_main_namespace
    @namespace = 'main'
  end
  
  # Load test page
  def test
  end
  
  # Translate key
  def translate
    @translation = ''
    if params[:key]
      @translation = t(:"#{params[:key]}")
    end
    render :json => { :translation => @translation }
  end
  
  # Load help page
  def help
    respond_to do |format|
      format.js do
        render '/static_pages/help'
      end
    end
  end
  
end