# Controller for Metadata management from Admin namespace and filtering in other namespaces.
class MetadataController < ApplicationController
  before_action :set_logged_in, :only => [:index, :edit, :update]
  before_action :current_metadatum_label, :only => [:edit, :update, :values, :filter_rule]
  before_action :set_filtered_amount, :only => [:coverage]
  
  # Show list of available metadata
  def index
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    set_pagination_params(0, 10, 'group')
    data = @metadata_handler.get_metadata(@number, @offset, @sort, @order)
    @metadata = data['metadata']
    @total = data['total']
    @corpora = @metadata_handler.load_corpora
  end
  
  # Show metadatum edit form
  def edit
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    if @metadatum
      @values = @metadata_handler.reformat_metadatum_values(@metadatum)
    else
      logger.warn "NO LABEL"
    end
  end
  
  # Update metadatum properties
  def update
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    if @metadatum
      updates = {}
      ['group','key','value_type','explorable','searchable'].each do |key|
        if params[key]
          updates[key] = params[key].to_s
        end
      end
      @metadata_handler.update_metadatum(@metadatum,updates)
    end
  end
  
  # Load metadata filter rule
  def filter_rule
    @filters = @metadata_handler.get_group_options(16, 'search')
    @rule_id = 0
    if params[:rule_id]
      @rule_id = params[:rule_id]
    end
    if @group && @key
      @values, value_count = @metadata_handler.load_values(@metadata_handler.generate_metadatum_object(@group,@key))
      @value = params[:value]
      @operator = params[:operator]
    end
  end
  
  # Load metadatum values by group and key
  def values
    @values, @value_count = @metadata_handler.load_values(@metadata_handler.generate_metadatum_object(@group,@key))
    @value_list_incomplete = false
    if @values.blank?
      mvalues = @metadata_handler.load_values_from_server(0, 0, "value", "asc", @group, @key)
      @values = mvalues.map{|x| x["value"]}
    else
      if !@value_count.blank? && @value_count > @values.size
        @value_list_incomplete = true
      end
    end
    @rule_id = 'rule0'
    if params[:rule_id]
      @rule_id = params[:rule_id]
    end
  end
  
  # Calculate coverage (token count) of metadata filters
  def coverage
  end
  
  protected
  
  # Get metadata filters from parameter
  def get_filters_from_params(par)
    filters = {}
    par.each do |key, value|
      if MetadataFiltersAllowed.include?(key)
        filters[key] = value
      end
    end
    filters
  end
  
  # Set current metadatum 
  def current_metadatum_label
    if params[:label]
      @label = params[:label]
      @group = @label.split('_')[0]
      @key = @label.sub(/#{@group}_/,'')
      @metadatum = @metadata_handler.get_metadatum(@metadata_handler.generate_metadatum_object(@group,@key))
    elsif params[:group] && params[:key]
      @group = params[:group].sub(/\_$/,'')
      @key = params[:key]
      @label = "#{@group}_#{@key}"
      @metadatum = @metadata_handler.get_metadatum(@metadata_handler.generate_metadatum_object(@group,@key))
    end
  end
  
end