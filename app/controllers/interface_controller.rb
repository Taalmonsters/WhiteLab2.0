# Controller for specific interface elements.
class InterfaceController < ApplicationController
  
  # Load translated PoS selection dropdown
  def pos_select_options
    @value = params[:value]
    @element = params[:element]
    @element_class = params[:element_class]
    @pos_heads = get_translated_pos_heads
    respond_to do |format|
      format.js { render '/pos_heads/select' }
    end
  end
  
end