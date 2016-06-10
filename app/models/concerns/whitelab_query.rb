# Base module for WhiteLab queries
module WhitelabQuery
  extend ActiveSupport::Concern
  
  included do
    belongs_to :user
    enum status: [ :waiting, :running, :counting, :finished, :failed ]
  end
  
  def self.find_from_params(klass, page, user_id, params)
    if params.has_key?(:id)
      query = klass.find(params[:id].to_i)
      query = nil if query && (query.user_id != user_id || query.is_changed?(params))
    elsif params.has_key?(:patt)
      query = klass.where(where_hash(params)).first
      query = nil if query && query.user_id != user_id
    end
    if query.nil?
      query = klass.create({
        :user_id => user_id, 
        :patt => params[:patt], 
        :within => params.has_key?(:within) ? params[:within] : nil, 
        :filter => params.has_key?(:filter) ? params[:filter] : nil, 
        :docpid => params.has_key?(:docpid) ? params[:docpid] : nil, 
        :input_page => page,
        :status => 0 })
      if klass.column_names.include? 'docpid' && params.has_key?(:docpid) && !params[:docpid].blank?
        query.docpid = params[:docpid]
        query.save
      end
    end
    return query.update_from_params(params)
  end
  
  def self.where_hash(params)
    hash = {:patt => params[:patt]}
    hash[:within] = params[:within] if params.has_key?(:within) && !params[:within].blank?
    hash[:filter] = params[:filter] if params.has_key?(:filter) && !params[:filter].blank?
    return hash
  end
  
  def self.history(user_id, hist_offset = 0, hist_number = 5)
    return self.class.name.constantize.where(:user_id => user_id).sort("updated_at desc").limit(hist_number).offset(hist_offset)
  end
  
  # Create URL parameter string for query with selected properties
  def assemble_url_params(only, translations = {})
    prms = []
    self.attributes.each do |name, value|
      if only.include?(name) && !value.blank?
        name = translations.keys.include?(name) ? translations[name] : name
        value = translations.keys.include?("#{name}_value") ? translations["#{name}_value"] : value
        prms << "#{name}=#{value}"
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
  
  def execute
    Thread.new do
      self.running! if self.waiting?
      res, backend_status = self.run
      self.counting! if backend_status == 1
      if backend_status == 2
        self.finished!
        self.hit_count = res['hit_count'] if hit_count.nil?
        self.document_count = res['document_count'] if document_count.nil?
        self.group_count = res['group_count'] if res.has_key?('group_count')
        self.save
      end
      self.failed! if backend_status == 3
    end
  end
  
  def result
    res, backend_status = self.run
    return res
  end
  
  def run
    backend = WhitelabBackend.instance
    return backend.search(self, backend.query_to_url(self))
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
    has_docpid = self.has_attribute?(:docpid)
    if attribute_is_changed?(view,params[:view])
      self.update_attributes({ :view => params[:view], :group => nil, :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
      self.update_attribute(:docpid, nil) if has_docpid
    elsif attribute_is_changed?(group,params[:group])
      self.update_attributes({ :group => params[:group], :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
      self.update_attribute(:docpid, nil) if has_docpid
    else
      changed = attributes_are_changed?(params.slice(:order, :sort, :number, :offset))
      changed = attributes_are_changed?(params.slice(:docpid)) if has_docpid && !changed
      if changed
        status = "waiting"
        order = params[:order] if attribute_is_changed?(order,params[:order])
        sort = params[:sort] if attribute_is_changed?(sort,params[:sort])
        number = params[:number] if attribute_is_changed?(number,params[:number])
        offset = params[:offset] if attribute_is_changed?(offset,params[:offset])
        docpid = params[:docpid] if has_docpid && attribute_is_changed?(docpid,params[:docpid])
        self.save!
      end
      if has_docpid && docpid.nil? && params.has_key?(:docpid) && !params[:docpid].blank?
        status = "waiting"
        docpid = params[:docpid]
        self.save!
      elsif has_docpid && !docpid.blank? && (!params.has_key?(:docpid) || params[:docpid].blank?)
        status = "waiting"
        docpid = nil
        self.save!
      end
    end
    return self
  end
  
  def total
    if view == 1
      return hit_count.nil? ? 0 : hit_count
    elsif view == 2
      return document_count.nil? ? 0 : document_count
    end
    return group_count.nil? ? 0 : group_count
  end
  
end