require "nokogiri"
# Interface controller for the Search namespace. It defines the separate pages and page elements in the Search namespace and inherits from the application interface controller and the Search controller concern.
class Search::InterfaceController < InterfaceController
  include WhitelabSearch
  before_action :set_field_values, :only => [:advanced_column, :advanced_box, :advanced_field]
  before_action :set_tab, :only => [:document]
  before_action :check_query_import, :only => [:expert]
  
  # Redirect from /search to /search/expert (with CQL query) or /search/simple (without CQL query)
  def search
    if params.has_key?(:patt)
      redirect_to search_expert_path, :params => params
    else
      redirect_to search_simple_path
    end
  end

  # Load the Simple Search page
  def simple
    respond_to do |format|
      format.html
    end
  end

  # Load the Extended Search page
  def extended
    respond_to do |format|
      format.html
    end
  end

  # Load the Advanced Search page
  def advanced
    respond_to do |format|
      format.html
    end
  end
  
  # Load column for the Advanced Search page
  def advanced_column
    respond_to do |format|
      format.js { render '/search/interface/advanced/column' }
    end
  end
  
  # Load box for the Advanced Search page
  def advanced_box
    respond_to do |format|
      format.js { render '/search/interface/advanced/box' }
    end
  end
  
  # Load field for the Advanced Search page
  def advanced_field
    respond_to do |format|
      format.js { render '/search/interface/advanced/field' }
    end
  end

  # Load the Expert Search page
  def expert
    respond_to do |format|
      format.html
      format.json { render json: @data }
    end
  end

  # Load the Document Search page
  def document
    respond_to do |format|
      flash[:error] = "Document '#{params[:xmlid]}' not found" if params.has_key?(:xmlid) && !params[:xmlid].blank? && !@document
      format.html
    end
  end
  
  protected
  
  # Get field values from parameters
  def set_field_values
    @field = {
      :column => params[:column] ? params[:column].to_i : 0,
      :box => params[:box] ? params[:box].to_i : 0,
      :field => params[:field] ? params[:field].to_i : 0
    }
    token_type = !params[:token_type] || !(['word', 'lemma', 'pos', 'phonetic']).include?(params[:token_type]) ? 'word' : params[:token_type]
    @pos_heads = get_translated_pos_heads
    @pos_feat_keys = load_pos_feature_keys.map{|feat| [feat, @pos_heads.map{|arr| load_pos_feature_data(arr[1].sub(/\.\*$/,'')) }.select{|pfeat| pfeat.keys.include?(feat) }.map{|pfeat| pfeat[feat].map{|val| val[1] } }.flatten.uniq] }.to_h
    @field_values = {
      :token_type => token_type,
      :operator => !params[:operator] || !['is', 'not', 'starts', 'ends', 'contains', 'regex'].include?(params[:operator]) ? 'is' : params[:operator],
      :input => params[:input],
      :batch => params[:batch] && params[:batch].eql?('true') ? true : false,
      :sensitive => params[:sensitive] && params[:sensitive].eql?('true') ? true : false,
      :startsen => params[:startsen] && params[:startsen].eql?('true') ? true : false,
      :endsen => params[:endsen] && params[:endsen].eql?('true') ? true : false,
      :repeat_from => params[:repeat_from] ? params[:repeat_from].to_i : 1,
      :repeat_to => params[:repeat_to] ? params[:repeat_to].to_i : 1
    }
  end
  
end