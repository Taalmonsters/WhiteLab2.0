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
  
  def pos_features
    @pos = params[:pos].sub(/\.\*$/,'') if params.has_key?(:pos) && !params[:pos].blank?
    @features = load_pos_feature_data(@pos)
    respond_to do |format|
      format.js { render '/pos_heads/refine' }
    end
  end
  
end