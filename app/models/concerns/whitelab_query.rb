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
  
  module ClassMethods
    def filter_xml_to_url_params(filter_xml)
      if filter_xml.css("filter").any?
        arr = []
        filter_xml.css("filter").each do |filter|
          if filter.css("values value").any?
            filter.css("values value").each do |value|
              arr << URI.escape("#{filter.at_css("field").content}=\"#{value.content}\"", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
            end
          else
            return "", true
          end
        end
        return "filter=(#{arr.join(")AND(")})", false
      elsif filter_xml.content.length > 0
        return "filter=#{filter_xml.content.sub(':','=')}", false
      end
      return "", false
    end
    
    def get_tokens_from_xml(tokens)
      arr = []
      tokens.css("> token").each do |token|
        arr << "[#{self.get_token_from_xml(token)}]#{token.css("> repeat").any? ? self.get_quantifier_from_token_xml(token) : ""}"
      end
      return arr.join("")
    end
    
    def get_token_from_xml(token)
      if token.css("> value").any?
        return "#{token.css("type").any? && ["word","lemma","pos","phonetic"].include?(token.at_css("type").content) ? token.at_css("type").content : "word"}#{token.css("operator").any? && token.at_css("operator").include?("not") ? "!=" : "="}\"#{self.get_token_value_from_xml(token)}\""
      elsif token.css("> and > token").any?
        arr = []
        token.css("> and > token").each do |token2|
          arr << self.get_token_from_xml(token2)
        end
        return "(#{arr.join("&")})"
      elsif token.css("> or > token").any?
        arr = []
        token.css("> or > token").each do |token2|
          arr << self.get_token_from_xml(token2)
        end
        return "(#{arr.join("|")})"
      end
    end
    
    def get_token_value_from_xml(token)
      op = token.at_css("operator").content if token.css("operator").any?
      return "#{["ends", "contains"].include?(op) ? ".*" : ""}#{token.at_css("value").content}#{["starts", "contains"].include?(op) ? ".*" : ""}"
    end
    
    def get_quantifier_from_token_xml(token)
      from = token.css("> repeat from").any? ? token.at_css("> repeat from").content.to_i : 0
      to = token.css("> repeat to").any? ? token.at_css("> repeat to").content.to_i : 0
      if to > 0
        return "{#{from > 0 && from < to ? "#{from}," : from > 0 && from == to ? "" : ","}#{to}}"
      elsif from == 0
        return "*"
      else
        return ""
      end
    end
  
    def xml_to_url_params(xml)
      return "Invalid XML format! No query patt found.", 0 unless xml.css("query patt").any?
      arr, error = self.query_xml_to_url_params(xml.at_css("query"))
      if error
        return "Invalid query format! #{arr[0]}", 0 if error
      elsif xml.css("filters").any?
        filter, error = self.filter_xml_to_url_params(xml.at_css("filters"))
        return "Invalid filter format!", 0 if error
        arr << filter unless filter.blank?
      end
      if error
        return "Invalid XML format!", 0
      else
        return arr.join("&"), 1
      end
    end

    def history(user_id, hist_offset = 0, hist_number = 5)
      return self.class.name.constantize.where(:user_id => user_id).sort("updated_at desc").limit(hist_number).offset(hist_offset)
    end
  end
  
  # Create URL parameter string for query with selected properties
  def assemble_url_params(only, translations = {})
    prms = []
    self.attributes.each do |name, value|
      if only.include?(name) && !value.blank?
        name = translations.keys.include?(name) ? translations[name] : name
        value = translations.keys.include?("#{name}_value") ? translations["#{name}_value"] : value
        prms << "#{name}=#{URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
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
    self.running!
    if !self.patt.nil? && ([1,2].include?(self.view) || !self.group.blank?)
      Rails.logger.debug "EXECUTING QUERY"
      if threaded
        Thread.new do
          res, backend_status = self.run
          self.output = res
          self.counting! if backend_status == 2
          self.finished! if backend_status == 3 || (max_count && res['hit_count'] >= max_count)
          self.failed! if backend_status == 4
          if [2,3].include?(backend_status)
            self.hit_count = res['hit_count']
            self.document_count = res['document_count']
            self.group_count = res['group_count'] if res.has_key?('group_count')
            self.sampleseed = res['sampleseed'] unless res['sampleseed'].blank?
            self.save
          end
        end
      else
        res, backend_status = self.run
        self.output = res
        self.counting! if backend_status == 2
        self.finished! if backend_status == 3 || (max_count && res['hit_count'] >= max_count)
        self.failed! if backend_status == 4
        if [2,3].include?(backend_status)
          self.hit_count = res['hit_count']
          self.document_count = res['document_count']
          self.group_count = res['group_count'] if res.has_key?('group_count')
          self.sampleseed = res['sampleseed'] unless res['sampleseed'].blank?
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
      self.exporting!
      Thread.new do
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