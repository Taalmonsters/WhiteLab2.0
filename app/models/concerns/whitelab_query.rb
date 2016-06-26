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
        prms << "#{name}=#{value.gsub('&','%26')}"
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
        self.running!
        res, backend_status = self.run
        self.output = res
        self.counting! if backend_status == 2
        self.finished! if backend_status == 3
        self.failed! if backend_status == 4
        if [2,3].include?(backend_status)
          self.hit_count = res['hit_count']
          self.document_count = res['document_count']
          self.group_count = res['group_count'] if res.has_key?('group_count')
          self.save
        end
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
        n_start = q.number
        o_start = q.offset
        status_start = q.status
        q.waiting!
        max = [EXPORT_LIMIT,self.total].min
        q.number = 1000
        o = 0
        FileUtils.mkpath(File.dirname(self.result_file))
        File.delete(self.result_file) if File.exists?(self.result_file)
        while o < max
          q.offset = o
          res = q.result
          CSV.open(self.result_file, "a", force_quotes: true) do |csv|
            csv << res['results'].first.keys if o == 0
            res['results'].each do |hash|
              csv << hash.values
            end
          end
          o += q.number
        end
        self.number = n_start
        self.offset = o_start
        # File.open(self.metadata_file, "w") do |xml|
          # xml.write(self.metadata)
        # end
        self.finished!
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
    backend = WhitelabBackend.instance
    return backend.search(self, backend.query_to_url(self))
  end
  
  def page
    return self.input_page
  end
  
  def total
    if view == 1
      return self.hit_count unless self.hit_count.nil?
    elsif view == 2
      return self.document_count unless self.document_count.nil?
    end
    return self.group_count unless self.group_count.nil?
    return 0
  end
  
end