# Controller for Metadata management from Admin namespace and filtering in other namespaces.
class MetadataController < ApplicationController
  include MetadataHelper
  
  before_action :set_logged_in, :only => [:index, :edit, :update]
  before_action :current_metadatum_label, :only => [:edit, :update, :values, :filter_rule]
  before_action :set_filtered_amount, :only => [:coverage]
  
  # Show list of available metadata
  def index
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    set_pagination_params(0, 10, 'group')
    backend = WhitelabBackend.instance
    data = backend.get_metadata(@number, @offset, @sort, @order)
    @metadata = data['metadata']
    @total = data['total']
    @corpora = backend.get_corpus_titles
  end
  
  # Show metadatum edit form
  def edit
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    if @label
      backend = WhitelabBackend.instance
      @metadatum = backend.get_metadatum_by_label(@label)
      @values = backend.get_metadatum_values_by_label(5, 0, "document_count", "desc", @label)
    else
      logger.warn "NO LABEL"
    end
  end
  
  # Update metadatum properties
  def update
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    if @label
      updates = {}
      ['group','key','value_type','explorable','searchable'].each do |key|
        if params[key]
          updates[key] = params[key].to_s
        end
      end
      backend = WhitelabBackend.instance
      backend.update_metadatum(@label,updates)
      @metadatum = backend.get_metadatum_by_label(@label)
    end
  end
  
  # Load metadata filter rule
  def filter_rule
    @filters = get_group_options(16, 'search')
    @rule_id = 0
    if params[:rule_id]
      @rule_id = params[:rule_id]
    end
    if @group && @key
      backend = WhitelabBackend.instance
      mvalues = backend.get_metadatum_values_by_group_and_key(0, 0, "value", "asc", @group, @key)
      if backend.get_backend_type().eql?('blacklab')
        @values = mvalues
      else
        @values = mvalues.map{|x| x["value"]}
      end
      @value = params[:value]
      @operator = params[:operator]
    end
  end
  
  # Load metadatum values by group and key
  def values
    @values = metadata_values(@group,@key)
    @value_list_incomplete = false
    if @values.blank?
      backend = WhitelabBackend.instance
      mvalues = backend.get_metadatum_values_by_group_and_key(0, 0, "value", "asc", @group, @key)
      if backend.get_backend_type().eql?('blacklab')
        @values = mvalues
      else
        @values = mvalues.map{|x| x["value"]}
      end
    else
      @value_count = metadata_value_count(@group,@key)
      if !@value_count.blank? && @value_count > METADATUM_VALUES_MAX
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
    elsif params[:group] && params[:key]
      @group = params[:group]
      @key = params[:key]
    end
  end
  
end