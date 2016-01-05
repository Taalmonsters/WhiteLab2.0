# Controller for specific interface elements.
class InterfaceController < ApplicationController
  before_action :current_column, :only => [:advanced_column, :advanced_box, :advanced_field]
  before_action :current_box, :only => [:advanced_column, :advanced_box, :advanced_field]
  before_action :current_field, :only => [:advanced_column, :advanced_box, :advanced_field]
  before_action :set_field_values, :only => [:advanced_column, :advanced_box, :advanced_field]
  
  # Load column for Search Advanced interface
  def advanced_column
    render '/search/advanced/column'
  end
  
  # Load box for Search Advanced interface
  def advanced_box
    render '/search/advanced/box'
  end
  
  # Load field for Search Advanced interface
  def advanced_field
    render '/search/advanced/field'
  end
  
  # Load translated PoS selection dropdown
  def pos_select_options
    @value = params[:value]
    @element = params[:element]
    @element_class = params[:element_class]
    @pos_heads = get_pos_heads(12, 0, "label", "asc")["pos_heads"].map{|x| [t(:"pos_heads.keys.#{x["label"]}").capitalize, x["label"]]}
    render '/pos_heads/select'
  end
  
  protected
  
  # Get field values from parameters
  def set_field_values
    @token_type = 'word'
    if params[:token_type] && ['word', 'lemma', 'pos', 'phonetic'].include?(params[:token_type])
      @token_type = params[:token_type]
    end
    @operator = 'is'
    if params[:operator] && ['is', 'not', 'starts', 'ends', 'contains', 'regex'].include?(params[:operator])
      @operator = params[:operator]
    end
    @input = nil
    if params[:input]
      @input = params[:input]
    end
    @batch = false
    if params[:batch] && params[:batch].eql?('true')
      @batch = true
    end
    @sensitive = false
    if params[:sensitive] && params[:sensitive].eql?('true')
      @sensitive = true
    end
    @startsen = false
    if params[:startsen] && params[:startsen].eql?('true')
      @startsen = true
    end
    @endsen = false
    if params[:endsen] && params[:endsen].eql?('true')
      @endsen = true
    end
    @repeat_from = 1
    if params[:repeat_from]
      @repeat_from = params[:repeat_from]
    end
    @repeat_to = 1
    if params[:repeat_to]
      @repeat_to = params[:repeat_to]
    end
  end
  
  # Get current column number from parameters
  def current_column
    if params[:column]
      @column = params[:column].to_i
    else
      @column = 0
    end
  end
  
  # Get current box number from parameters
  def current_box
    if params[:box]
      @box = params[:box].to_i
    else
      @box = 0
    end
  end
  
  # Get current field number from parameters
  def current_field
    if params[:field]
      @field = params[:field].to_i
    else
      @field = 0
    end
  end
  
end