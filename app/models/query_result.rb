# Module for Query Results to be connected to queries
class QueryResult < ActiveRecord::Base
  include BackendHelper
  # include DataFormatHelper
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
    is_explore_namespace = namespace.eql?('explore')
    result = query.query_result
    if query && !result.blank?
      new_params = result.attributes.except("id", "result", "status", "created_at", "updated_at")
    end
    
    ["within", "number", "offset", "view", "group", "patt", "filter"].each do |attr|
      if params.has_key?(:"#{attr}")
        new_params[attr] = params[:"#{attr}"]
      end
    end
    has_view = new_params.has_key?("view")
    if !has_view
      new_params["view"] = is_explore_namespace ? 8 : 1
    end
    new_params["within"] = 'document' if !new_params.has_key?("within")
    new_params["offset"] = 0 if !new_params.has_key?("offset")
    new_params["number"] = 50 if !new_params.has_key?("number")
    new_params["patt"] = query.patt if !new_params.has_key?("patt") && query
    new_params["filter"] = query.filter if !new_params.has_key?("filter") && query
    
    if is_explore_namespace
      new_params["group"] = !listtype.blank? && !listtype.eql?('word') ? 'hit_'+listtype : 'hit_text'
    end
    return new_params
  end
  
  # Execute query
  def execute(why)
    logger.debug("Executing query, because: #{why}")
    if (view == 8 || view == 16) && group.blank?
      errors.add(:group, "has to be defined")
    else
      self.run(true, nil, nil)
    end
  end
  
  # Execute query in thread
  def execute_threaded(why)
    logger.debug("Executing query, because: #{why}")
    if (view == 8 || view == 16) && group.blank?
      errors.add(:group, "has to be defined")
    else
      Thread.new do
        self.run(true, nil, nil)
      end
    end
  end
  
  # Run query and store results
  def run(count, offs, nmb)
    self.update_attribute(:status, 1)
    data = WhitelabBackend.instance.get_search_results_for_query(self, nil, offs, nmb)
    if self.view == 4
      Thread.new do
        self.update_attribute(:result, format_for_vocabulary_growth(data['content']))
      end
    else
      if !data.has_key?('results')
        logger.error "QueryResult.run: no results in data"
      end
      self.update_attribute(:result, data['results'])
    end
    if count
      self.update_attribute(:group_count, nil)
      do_count
    end
  end
  
  # Perform hit, document, and group count for query
  def do_count
    Thread.new do
      not_counting = !self.is_counting
      if self.hit_count.blank? && not_counting
        self.update_attribute(:status, 2)
        get_count('hit_count')
      end
      if self.document_count.blank? && not_counting
        self.update_attribute(:status, 3)
        get_count('document_count')
      end
      if [8, 16].include?(self.view) && self.group_count.blank? && not_counting
        self.update_attribute(:status, 4)
        get_count('group_count')
      end
      finish_counting
    end
  end
  
  # Get total result count for query
  def total
    if [8, 16].include?(view)
      group_count || number
    elsif view == 2
      document_count || number
    else
      hit_count || number
    end
  end
  
  # Get count from existing QueryResult
  def get_count(attr)
    if self.read_attribute(attr).blank?
      results = []
      if attr.eql?('group_count')
        results = QueryResult.where({:patt => patt, :filter => filter, :within => within, :group => group, :status => 10}).where.not(:"#{attr}" => nil)
      else
        results = QueryResult.where("patt = ? AND filter = ? AND within = ? AND #{attr} IS NOT NULL AND status = ?", patt, filter, within, 10)
      end
      if results.any?
        self.update_attribute(:"#{attr}", results.first.read_attribute(attr))
      else
        calculate_count(attr)
      end
    end
    self.update_attribute(:status, 1)
    self.read_attribute(attr)
  end
  
  # Set count in QueryResult
  def set_count(data, attr, offset)
    if !data.blank? && data.has_key?(attr)
      count = offset + data[attr]
      self.update_attribute(:"#{attr}", count)
    else
      self.update_attribute(:status, 5)
    end
  end
  
  # Calculate count from index
  def calculate_count(attr)
    view = 1
    if attr.eql?('group_count')
      view = 8
    elsif attr.eql?('document_count')
      view = 2
    end
    set_count(WhitelabBackend.instance.get_search_result_counts_for_query(self, nil, view, 0, 0), attr, 0)
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
    if status == 0
      'Waiting'
    elsif status == 1
      'Running'
    elsif status > 1 && status < 5
      'Counting'
    elsif status == 5
      'Error'
    elsif status == 10
      'Finished'
    end
  end
  
  # Check if QueryResult is new
  def is_new
    status == 0
  end
  
  # Check if QueryResult is running
  def is_running
    status == 1
  end
  
  # Check if QueryResult is counting
  def is_counting
    status > 1 && status < 5
  end
  
  # Check if QueryResult has an error
  def has_error
    status == 5
  end
  
  # Check if QueryResult has completed
  def is_finished
    [5,10].include?(status)
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
