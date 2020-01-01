# Controller for specific interface elements.
class InterfaceController < ApplicationController
  
  # Load values for PoS selection dropdown
  def pos_select_options
    @value = params[:value]
    @element = params[:element]
    @element_class = params[:element_class]
    if params.has_key?(:feat) && !params[:feat].blank?
      @pos_heads = load_pos_feature_value_data(params[:feat])
    else
      @pos_heads = get_translated_pos_heads
    end
    respond_to do |format|
      format.js { render '/pos_heads/select' }
    end
  end

  # Load values for PoS feature selection dropdown
  def pos_features
    @pos = params[:pos].sub(/\.\*$/,'') if params.has_key?(:pos) && !params[:pos].blank?
    @features = load_pos_feature_data(@pos)
    @values = params[:values].split(',') if params.has_key?(:values)
    respond_to do |format|
      format.js { render '/pos_heads/refine' }
    end
  end
  
  protected

  # Check the validity of an imported XML query. If the query is valid, a URL is constructed for the imported query.
  def check_query_import
    if params.has_key?(:file)
      @data = {}
      xml = Nokogiri::XML(params[:file].read)
      if xml && xml.css(@namespace).any?
        url_params, status = "#{@namespace.capitalize}::Query".constantize.xml_to_url_params(xml.css(@namespace).first)
        if status == 1
          @data["url"] = BASE_PATH + "/#{@namespace}/#{action_name}?#{url_params}#results"
        else
          @data["error"] = url_params
        end
      else
        @data["error"] = "Invalid XML format! No explore tag found."
      end
    end
  end
  
end