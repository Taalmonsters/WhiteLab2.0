# Base module for WhiteLab queries
module WhitelabQuery
  extend ActiveSupport::Concern
  include DataFormatHelper
  
  included do
    belongs_to :user
    enum status: [ :waiting, :running, :counting, :finished, :failed ]
    enum export_status: [ :not_exported, :exporting, :exported ]
    attr_accessor :output
  end
  
  def self.find_from_params(klass, page, user_id, params)
    if params.has_key?(:patt) || params.has_key?(:filter)
      options = klass.where(klass.where_data(user_id, page, params))
      query = options.first if options.size == 1
      unless query
        [:view, :group, :input_page].each do |param|
          if params.has_key?(param) && !params[param].blank?
            filtered_options = options.where({param => params[param]})
            options = filtered_options.any? ? filtered_options : options
          end
        end
        query = options.first
      end
    end
    if query.nil?
      query = klass.create(klass.create_hash(user_id, page, params))
    end
    query = query.update_from_params(params)
    return query
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
    if !self.patt.nil? && ([1,2].include?(self.view) || !self.group.blank?)
      Rails.logger.debug "EXECUTING QUERY"
      Thread.new do
        self.running! if self.waiting?
        res, backend_status = self.run
        Rails.logger.debug "RESULT FROM BACKEND (status code #{backend_status}):"
        Rails.logger.debug res
        self.output = res
        self.counting! if backend_status == 2
        if backend_status == 3
          self.finished!
          self.hit_count = res['hit_count'] if hit_count.nil?
          self.document_count = res['document_count'] if document_count.nil?
          self.group_count = res['group_count'] if res.has_key?('group_count')
          self.save
        end
        self.failed! if backend_status == 4
      end
    else
      Rails.logger.debug "NOT EXECUTING QUERY"
    end
  end
  
  def export
    if self.finished? && !self.exporting?
      Thread.new do
        self.exporting!
        q = self.clone
        q.status = "waiting"
        q.number = [EXPORT_LIMIT,self.total].min
        res = q.result
        FileUtils.mkpath(File.dirname(self.result_file))
        CSV.open(self.result_file, "wb", force_quotes: true) do |csv|
          csv << res['results'].first.keys
          res['results'].each do |hash|
            csv << hash.values
          end
        end
        # File.open(self.metadata_file, "w") do |xml|
          # xml.write(self.metadata)
        # end
        self.exported!
      end
    end
  end
  
  def result
    Rails.logger.debug "GET QUERY RESULT"
    return self.output if self.finished? && !self.output.blank?
    self.output, backend_status = self.run
    return self.output
  end
  
  def run
    Rails.logger.debug "RUNNING QUERY"
    backend = WhitelabBackend.instance
    url = backend.query_to_url(self)
    Rails.logger.debug "URL: #{url}"
    res, stat = backend.search(self, url)
    Rails.logger.debug "RESPONSE AFTER RUN:"
    Rails.logger.debug res
    return res, stat
  end
  
  def page
    return self.input_page
  end
  
  def total
    if view == 1
      return self.hit_count.nil? ? self.total : self.hit_count
    elsif view == 2
      return self.document_count.nil? ? self.total : self.document_count
    end
    return self.group_count.nil? ? self.total : self.group_count
  end
  
end