# Module for Search Queries, includes WhitelabQuery
class Search::Query < ActiveRecord::Base
  include WhitelabQuery
  
  before_destroy :delete_export_files
  
  def delete_export_files
    dir = Rails.root.join('data','search',self.id.to_s)
    FileUtils.rm_r(dir) if File.exists?(dir)
  end
  
  def result_file(tsv = false)
    return Rails.root.join('data','search',self.id.to_s,tsv ? 'result.tsv' : 'result.csv')
  end
  
  def metadata_file
    return Rails.root.join('data','search',self.id.to_s,'metadata.xml')
  end
  
  def metadata
    return {
      :patt => self.patt,
      :within => self.within,
      :filter => self.filter,
      :view => self.view,
      :group => self.group
    }.to_xml
  end
  
  # Generate filename for download
  def generate_filename
    filename = view_to_path(view)
    if patt.eql?('[]')
      filename = filename+'_p=empty'
    else
      filename = filename+'_p='+patt.gsub(/\]\[/,' ').gsub(/\[*(word|lemma|pos|phonetic)=\"/,'').gsub(/\"\]*/,'')
    end
    filename = filename+'_w='+within if !within.eql?('document')
    filename = filename+'_f='+filter if !filter.blank?
    filename = filename+'_g='+group if !group.blank?
    return filename
  end
  
  def to_xml
    hash = { search: { query: { patt: self.patt, within: self.within, view: self.view, offset: self.offset, number: self.number } } }
    hash[:search][:query][:gap_values_tsv] = self.gap_values_tsv unless self.gap_values_tsv.blank?
    hash[:search][:query][:group] = self.group unless self.group.blank?
    hash[:search][:query][:viewgroup] = self.viewgroup unless self.viewgroup.blank?
    hash[:search][:query][:sample] = self.sample unless self.sample.blank?
    hash[:search][:query][:samplenum] = self.samplenum unless self.samplenum.blank?
    hash[:search][:query][:sampleseed] = self.sampleseed unless self.sampleseed.blank?
    hash[:search][:filters] = self.filter unless self.filter.blank?
    return hash.to_xml(:root => 'whitelab')
  end
  
  def self.find_from_params(page, user, params)
    params[:group] = params[:group].gsub('%3B',';') if params.has_key?(:group)
    if params.has_key?(:id)
      query = user.search_queries.find(params[:id].to_i)
      query = nil if query && query.is_changed?(page, params)
    end
    if !query && params[:patt].include?(';')
      params[:patt].split(';').each_with_index do |patt,i|
        params[:patt] = patt
        if i == 0
          query = WhitelabQuery.find_from_params(Search::Query, page, user.id, params)
        else
          WhitelabQuery.find_from_params(Search::Query, page, user.id, params).execute
        end
      end
    end
    return query ? query : WhitelabQuery.find_from_params(Search::Query, page, user.id, params)
  end
  
  def self.create_hash(user_id, page, params)
    return {
      :user_id => user_id, 
      :patt => URI.unescape(params[:patt]), 
      :within => params.has_key?(:within) ? params[:within] : 'document', 
      :filter => params.has_key?(:filter) && !params[:filter].blank? ? params[:filter] : nil, 
      :group => params.has_key?(:group) ? params[:group] : nil,
      :viewgroup => params.has_key?(:viewgroup) ? params[:viewgroup] : nil,
      :sample => params.has_key?(:sample) && !params[:sample].blank? ? params[:sample].to_i : nil,
      :samplenum => params.has_key?(:samplenum) && !params[:samplenum].blank? ? params[:samplenum].to_i : nil,
      :sampleseed => params.has_key?(:sampleseed) && !params[:sampleseed].blank? ? params[:sampleseed].to_i : nil,
      :gap_values_tsv => params.has_key?(:gap_values_tsv) && !params[:gap_values_tsv].blank? ? params[:gap_values_tsv] : nil,
      :view => params.has_key?(:view) ? params[:view].to_i : 1, 
      :input_page => page,
      :status => 0
    }
  end
  
  def self.where_data(user_id, page, params)
    return {
      :user_id => user_id,
      :patt => URI.unescape(params[:patt]),
      :within => params.has_key?(:within) ? params[:within] : 'document',
      :filter => params.has_key?(:filter) && !params[:filter].blank? ? params[:filter] : nil,
      :group => params.has_key?(:group) && !params[:group].blank? ? params[:group] : nil,
      :viewgroup => params.has_key?(:viewgroup) && !params[:viewgroup].blank? ? params[:viewgroup] : nil,
      :sample => params.has_key?(:sample) && !params[:sample].blank? ? params[:sample].to_i : nil,
      :samplenum => params.has_key?(:samplenum) && !params[:samplenum].blank? ? params[:samplenum].to_i : nil,
      :sampleseed => params.has_key?(:sampleseed) && !params[:sampleseed].blank? ? params[:sampleseed].to_i : nil,
      :gap_values_tsv => params.has_key?(:gap_values_tsv) && !params[:gap_values_tsv].blank? ? params[:gap_values_tsv] : nil
    }
  end
  
  def self.query_xml_to_url_params(query_xml)
    arr = []
    if query_xml.css("patt tokens token").any?
      arr << "patt=#{URI.escape(self.get_tokens_from_xml(query_xml.css("patt > tokens")), Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    elsif query_xml.at_css("patt").content.length > 0
      arr << "patt=#{URI.escape(query_xml.at_css("patt").content, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    else
      return ["No valid patt"], true
    end
    if query_xml.css("group context").any?
      group, error = self.get_complex_group_from_xml(query_xml)
      return [group], true if error
      arr << "group=#{URI.escape(group, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    elsif query_xml.css("group").any? && query_xml.at_css("group").content.length > 0
      group = query_xml.at_css("group").content
      arr << "group=#{URI.escape(group, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
      if query_xml.css("viewgroup").any?
        arr << "view=1"
      elsif !query_xml.css("view").any?
        arr << "view=8"
      end
    end
    ["within","viewgroup","offset","sample","samplenum","sampleseed","gap_values_tsv"].each do |param|
      arr << "#{param}=#{URI.escape(query_xml.at_css(param).content, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}" if query_xml.css(param).any?
    end
    arr << "view=#{query_xml.at_css("view").content}" if query_xml.css("view").any? && !arr.select{|str| str.start_with?("view=") }.any?
    arr << "number=#{query_xml.at_css("number").content}" if query_xml.css("number").any? && [50,100,200].include?(query_xml.at_css("number").content.to_i)
    return arr, false
  end
  
  def self.get_complex_group_from_xml(query_xml)
    group = query_xml.at_css("group context").content
    if group.eql?("field")
      return "Missing field for grouping!", true unless query_xml.css("group field").any?
      group = query_xml.at_css("group field").content
    else
      group = query_xml.css("group type").any? ? "#{group}:#{query_xml.at_css("group type").content}" : "word"
      group = query_xml.css("group case").any? ? "#{group}:#{query_xml.at_css("group case").content}" : "s"
      if query_xml.at_css("group context").content.eql?("context")
        if query_xml.css("group left set").any? || query_xml.css("group hit full").any? || query_xml.css("group hit set").any? || query_xml.css("group right set").any?
          first = true
          group, first = self.add_context_to_group(group, "L", query_xml.css("group left set"), first, true) if query_xml.css("group left set").any?
          if query_xml.css("group hit full").any?
            group = "#{group}#{first ? ':' : ';'}H"
            first = false
          else
            group, first = self.add_context_to_group(group, set.at_css("direction").content.eql?('start') ? 'H' : 'E', query_xml.css("group hit set"), first, set.at_css("direction").content.eql?('end')) if query_xml.css("group hit set").any?
          end
          group, first = self.add_context_to_group(group, "R", query_xml.css("group right set"), first, false) if query_xml.css("group right set").any?
        else
          return "Missing group context specification!", true
        end
      end
    end
    return group, false
  end
  
  def self.add_context_to_group(group, letter, sets, first, reverse)
    sets.each do |set|
      if reverse
        from = set.at_css("from").content.to_i
        to = set.at_css("to").content.to_i
        range = to < from ? [to..from] : [from..to]
        range.to_a.reverse.each do |i|
          group = "#{group}#{first ? ':' : ';'}#{letter}#{i}-#{i}"
          first = false
        end
      else
        group = "#{group}#{first ? ':' : ';'}#{letter}#{set.at_css("from").content}-#{set.at_css("to").content}"
        first = false
      end
    end
    return group, first
  end
  
  def add_hits_group(hits_group)
    hits_group.gsub!(/([\(\)\[\]\'\"\?\!])/){|s| "\\"+s}
    qgroup_parts = group.split(':')
    context_group_label = group_to_label(qgroup_parts[1])
    if self.group.start_with?('hit')
      patt_parts = self.patt.gsub(/(^\[|\]$)/,'').split('][')
      group_parts = hits_group.split(' ')
      g = group_to_label(qgroup_parts[1])
      new_parts = []
      patt_parts.each_with_index do |part,i|
        if part.include?("#{g}=")
          new_parts << '['+g+'="(?c)'+group_parts[i]+'"]'
        elsif group_parts.size > i
          new_parts << "[#{part}&#{g}=\"(?c)#{group_parts[i]}\"]"
        else
          new_parts << "[#{part}]"
        end
      end
      self.patt = new_parts.join('')
    elsif self.group.start_with?('wordleft')
      self.patt = "[#{context_group_label}=\"(?c)#{hits_group}\"]#{self.patt}"
    elsif self.group.start_with?('wordright')
      self.patt = "#{self.patt}[#{context_group_label}=\"(?c)#{hits_group}\"]"
    elsif self.filter.blank?
      self.filter = "(#{self.group}=\"#{hits_group}\")"
    else
      self.filter = "#{self.filter}AND(#{self.group}=\"#{hits_group}\")"
    end
  end
  
  def is_changed?(page, params)
    return true if attribute_is_changed?(patt,params[:patt])
    return true if attribute_is_changed?(within,params[:within])
    return true if attribute_is_changed?(filter,params[:filter])
    return false
  end
  
  def update_from_params(params)
    new_query = self
    new_query.waiting! if new_query.failed?
    if attribute_is_changed?(new_query.view,params[:view].to_i)
      if !new_query.not_exported?
        new_query = self.dup
        new_query.not_exported!
      end
      new_query.update_attributes({ :view => params[:view].to_i, :group => nil, :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    elsif attribute_is_changed?(new_query.group,params[:group])
      if !new_query.not_exported?
        new_query = self.dup
        new_query.not_exported!
      end
      new_query.update_attributes({ :group => params[:group], :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    else
      changed = new_query.attributes_are_changed?(params.slice(:order, :sort, :number, :offset))
      if changed
        new_query.waiting!
        new_query.order = params[:order] if attribute_is_changed?(order,params[:order])
        new_query.sort = params[:sort] if attribute_is_changed?(sort,params[:sort])
        new_query.number = params[:number].to_i if attribute_is_changed?(number,params[:number].to_i)
        new_query.offset = params[:offset].to_i if attribute_is_changed?(offset,params[:offset].to_i)
        new_query.save!
      end
    end
    return new_query
  end
  
end
