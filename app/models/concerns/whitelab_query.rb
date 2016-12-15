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
      options_without_exports = options.select{|x| x.not_exported? }
      query = options_without_exports.first if options_without_exports.size > 0
      query = options.first if options.size > 0 && !query
      unless query
        [:view, :group, :input_page, :viewgroup].each do |param|
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
        prms << "#{name}=#{value.to_s.gsub('&','%26').gsub('\\','%5C').gsub(';','%3B')}"
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
  
  def columns
    self.patt.scan(/\]\[/).count + 1
  end
  
  def execute(threaded = true, max_count = nil)
    if !self.patt.nil? && ([1,2].include?(self.view) || !self.group.blank?)
      Rails.logger.debug "EXECUTING QUERY"
      if threaded
        Thread.new do
          self.running!
          res, backend_status = self.run
          self.output = res
          self.counting! if backend_status == 2
          self.finished! if backend_status == 3 || (max_count && res['hit_count'] >= max_count)
          self.failed! if backend_status == 4
          if [2,3].include?(backend_status)
            self.hit_count = res['hit_count']
            self.document_count = res['document_count']
            self.group_count = res['group_count'] if res.has_key?('group_count')
            self.save
          end
        end
      else
        self.running!
        res, backend_status = self.run
        self.output = res
        self.counting! if backend_status == 2
        self.finished! if backend_status == 3 || (max_count && res['hit_count'] >= max_count)
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
    Rails.logger.debug("EXPORTING WL QUERY")
    if self.finished? && !self.exporting?
      Thread.new do
        self.exporting!
        n_start = self.number
        o_start = self.offset
        status_start = self.status
        self.waiting!
        max = [EXPORT_LIMIT,self.total].min
        self.number = 1000
        o = 0
        csv_file = self.result_file
        FileUtils.mkpath(File.dirname(csv_file))
        File.delete(csv_file) if File.exists?(csv_file)
        tsv_file = self.result_file(true)
        File.delete(tsv_file) if File.exists?(tsv_file)
        while o < max
          self.offset = o
          res = self.result(false)
          Rails.logger.debug "RESULT: #{res}"
          CSV.open(csv_file, "a", force_quotes: true) do |csv|
            csv << res['results'].first.keys if o == 0
            res['results'].each do |hash|
              csv << hash.values
            end
          end
          File.open(tsv_file, "a") do |tsv|
            tsv.write res['results'].first.keys.join("\t")+"\n" if o == 0
            res['results'].each do |hash|
              tsv.write hash.values.join("\t")+"\n"
            end
          end
          o += self.number
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
  
  def page
    return self.input_page
  end
  
  def result(threaded = true)
    return self.output if (self.finished? || self.counting?) && self.output && !self.output.blank?
    Rails.logger.debug "GET QUERY RESULT"
    self.execute(threaded)
    return self.output
  end
  
  def run
    backend = WhitelabBackend.instance
    return backend.search(self, backend.query_to_url(self))
  end
  
  def selected_group
    return self.group unless self.group =~ /^(hit|word|context)/
    position, type, rest = self.group.split(':',3)
    return position.eql?('context') ? position : "#{position}:#{type}"
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