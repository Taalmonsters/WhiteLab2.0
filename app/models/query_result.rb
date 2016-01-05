# Module for Query Results to be connected to queries
class QueryResult < ActiveRecord::Base
  include DatabaseHelper
  include DataFormatHelper
  has_many :search_queries
  has_many :explore_queries
  has_and_belongs_to_many :export_queries
  
  serialize :result, JSON
  
  # Find of create QueryResult from parameters
  def self.get_current_query_result(params)
    results = QueryResult.where({
      :patt => params["patt"], 
      :filter => params["filter"], 
      :within => params["within"], 
      :view => params["view"].to_i, 
      :group => params["group"], 
      :sort => params["sort"], 
      :order => params["order"], 
      :offset => params["offset"].to_i, 
      :number => params["number"].to_i, 
      :status => [0,1,2,10]
    }).order("status DESC, updated_at DESC")
    if results.any?
      return results.first
    else
      params["status"] = 0
      return QueryResult.create(params)
    end
  end
  
  # Get default parameters
  def self.add_default_params(namespace, query, params, listtype)
    new_params = {}
    if query && !query.query_result.blank?
      new_params = query.query_result.attributes.except("id", "result", "status", "created_at", "updated_at")
    end
    
    ["within", "number", "offset", "view", "group", "patt", "filter"].each do |attr|
      if params.has_key?(:"#{attr}")
        new_params[attr] = params[:"#{attr}"]
      end
    end
    
    if !new_params.has_key?("within")
      new_params["within"] = 'document'
    end
    if !new_params.has_key?("view") && namespace.eql?('search')
      new_params["view"] = 1
    elsif !new_params.has_key?("view") && namespace.eql?('explore')
      new_params["view"] = 8
    end
    if !new_params.has_key?("offset")
      new_params["offset"] = 0
    end
    if !new_params.has_key?("number")
      new_params["number"] = 50
    end
    if !new_params.has_key?("patt") && query
      new_params["patt"] = query.patt
    end
    if !new_params.has_key?("filter") && query
      new_params["filter"] = query.filter
    end
    
    if namespace.eql?('explore')
      if !listtype.blank? && !listtype.eql?('word')
        new_params["group"] = 'hit_'+listtype
      else
        new_params["group"] = 'hit_text'
      end
    end
    return new_params
  end
  
  # Execute query
  def execute(threaded, why)
    if (view == 8 || view == 16) && group.blank?
      errors.add(:group, "has to be defined")
    else
      if threaded
        Thread.new do
          self.run(true, nil, nil)
        end
      else
        self.run(true, nil, nil)
      end
    end
  end
  
  # Run query and store results
  def run(count, o, n)
    self.update_attribute(:status, 1)
    data = get_search_results_for_query(self, nil, o, n)
    if self.view == 4
      Thread.new do
        self.update_attribute(:result, format_for_vocabulary_growth(data['content']))
      end
    else
      self.update_attribute(:result, data['results'])
    end
    if count
      do_count
    end
  end
  
  # Perform hit, document, and group count for query
  def do_count
    Thread.new do
      if self.hit_count.blank? && !self.is_counting
        self.update_attribute(:status, 2)
        get_count('hit_count')
        self.update_attribute(:status, 1)
      end
      if self.document_count.blank? && !self.is_counting
        self.update_attribute(:status, 3)
        get_count('document_count')
        self.update_attribute(:status, 1)
      end
      if [8, 16].include?(self.view) && self.group_count.blank? && !self.is_counting
        self.update_attribute(:status, 4)
        get_count('group_count')
        self.update_attribute(:status, 1)
      end
      finish_counting
    end
  end
  
  # Get total result count for query
  def total
    if [8, 16].include?(self.view)
      self.group_count || self.number
    elsif self.view == 2
      self.document_count || self.number
    else
      self.hit_count || self.number
    end
  end
  
  # Get count from existing QueryResult
  def get_count(attr)
    if self.read_attribute(attr).blank?
      results = []
      if attr.eql?('group_count')
        results = QueryResult.where({:patt => self.patt, :filter => self.filter, :within => self.within, :group => self.group, :status => 10}).where.not(:"#{attr}" => nil)
      else
        results = QueryResult.where("patt = ? AND filter = ? AND within = ? AND #{attr} IS NOT NULL AND status = ?", self.patt, self.filter, self.within, 10)
      end
      if results.any?
        self.update_attribute(:"#{attr}", results.first.read_attribute(attr))
      else
        calculate_count(attr)
      end
    end
    self.read_attribute(attr)
  end
  
  # Calculate count from index
  def calculate_count(attr)
    view = 1
    if attr.eql?('group_count')
      view = 8
    elsif attr.eql?('document_count')
      view = 2
    end
    set_count(get_search_result_counts_for_query(self, nil, view, 0, 0), attr, 0)
  end
  
  # Set count in QueryResult
  def set_count(data, attr, offset)
    if data.blank?
      self.update_attribute(:status, 5)
    elsif data.has_key?(attr)
      count = offset + data[attr]
      self.update_attribute(:"#{attr}", count)
    else
      self.update_attribute(:status, 5)
    end
  end
  
  # Complete query if QueryResult has finished counting
  def finish_counting
    if is_finished_counting
      self.update_attribute(:status, 10)
      return 1
    end
    return 0
  end
  
  # Check if query has finished counting
  def is_finished_counting
    !self.hit_count.blank? && !self.document_count.blank? && (![8, 16].include?(self.view) || !self.group_count.blank?)
  end
  
  # Get QueryResult status string
  def text_status
    if self.status == 0
      'Waiting'
    elsif self.status == 1
      'Running'
    elsif self.status > 1 && self.status < 5
      'Counting'
    elsif self.status == 5
      'Error'
    elsif self.status == 10
      'Finished'
    end
  end
  
  # Check if QueryResult is new
  def is_new
    self.status == 0
  end
  
  # Check if QueryResult is running
  def is_running
    self.status == 1
  end
  
  # Check if QueryResult is counting
  def is_counting
    self.status > 1 && self.status < 5
  end
  
  # Check if QueryResult has an error
  def has_error
    self.status == 5
  end
  
  # Check if QueryResult has completed
  def is_finished
    [5,10].include?(self.status)
  end
  
  # Check if QueryResult is updated
  def is_updated(params, for_count)
    if params.has_key?(:patt) && !self.patt.eql?(params[:patt])
      return true
    elsif params.has_key?(:filter) && !self.filter.eql?(params[:filter])
      return true
    elsif params.has_key?(:number) && !params[:number].blank? && !self.number.eql?(params[:number].to_i) && !for_count
      return true
    elsif params.has_key?(:offset) && !params[:offset].blank? && !self.offset.eql?(params[:offset].to_i) && !for_count
      return true
    elsif params.has_key?(:view) && !params[:view].blank? && !self.view.eql?(params[:view].to_i) && (!for_count || params.has_key?(:view) >= 8)
      return true
    elsif params.has_key?(:group) && !self.group.eql?(params[:group])
      return true
    elsif params.has_key?(:within) && !self.within.eql?(params[:within])
      return true
    elsif params.has_key?(:sort) && !self.sort.eql?(params[:sort]) && !for_count
      return true
    elsif params.has_key?(:order) && !self.order.eql?(params[:order]) && !for_count
      return true
    end
    return false
  end
end
