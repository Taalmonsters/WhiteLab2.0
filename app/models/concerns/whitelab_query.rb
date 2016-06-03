# Base module for WhiteLab queries
module WhitelabQuery
  extend ActiveSupport::Concern
  
  included do
    belongs_to :user
    enum status: [ :waiting, :running, :counting, :finished, :failed ]
  end
  
  def self.find_from_params(page, user_id, params)
    klass = self.class.name.constantize
    if params.has_key?(:id)
      query = klass.find(params[:id].to_i)
      query = nil if query && query.is_changed?(params)
    end
    query = klass.create({
      :user_id => user_id, 
      :patt => params[:patt], 
      :within => params.has_key?(:within) ? params[:within] : nil, 
      :filter => params.has_key?(:filter) ? params[:filter] : nil, 
      :input_page => page,
      :status => 0 }) unless query
    return query.update_from_params(params)
  end
  
  def self.history(user_id, hist_offset = 0, hist_number = 5)
    return self.class.name.constantize.where(:user_id => user_id).sort("updated_at desc").limit(hist_number).offset(hist_offset)
  end
  
  # Create URL parameter string for query with selected properties
  def assemble_url_params(only)
    prms = []
    self.attributes.each do |name, value|
      if only.include?(name)
        prms << name+'='+value.to_s
      end
    end
    return prms.join('&')
  end
  
  def attribute_is_changed?(attr,param)
    return false if param.blank?
    return attr.blank? || !param.to_s.eql?(attr.to_s)
  end
  
  def attributes_are_changed?(params)
    changed = false
    params.each do |param_key, param_value|
      changed = attribute_is_changed?(self.send(param_key.to_s),param_value)
      break if changed
    end
    return changed
  end
  
  def run
    # TODO
    return WhitelabBackend.instance.execute_query(self)
  end
  
  def is_changed?(params)
    return true if attribute_is_changed?(patt,params[:patt])
    return true if attribute_is_changed?(within,params[:within])
    return true if attribute_is_changed?(filter,params[:filter])
    return false
  end
  
  def page
    return input_page
  end
  
  def update_from_params(params)
    if attribute_is_changed?(view,params[:view])
      self.update_attributes({ :view => params[:view], :group => nil, :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    elsif attribute_is_changed?(group,params[:group])
      self.update_attributes({ :group => params[:group], :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    else
      changed = attributes_are_changed?(params.only([:order, :sort, :number, :offset]))
      if changed
        status = "waiting"
        order = params[:order] if attribute_is_changed?(order,params[:order])
        sort = params[:sort] if attribute_is_changed?(sort,params[:sort])
        number = params[:number] if attribute_is_changed?(number,params[:number])
        offset = params[:offset] if attribute_is_changed?(offset,params[:offset])
        self.save!
      end
    end
    return self
  end
  
end