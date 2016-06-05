# Controller for all static public pages.
class StaticPagesController < ApplicationController
  
  # Load info page
  def info
    @tab = 'info'
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