# Module for Explore Queries, includes WhitelabQuery
class Explore::Query < ActiveRecord::Base
  include WhitelabQuery
  
  before_destroy :delete_export_files
  
  def delete_export_files
    dir = Rails.root.join('data','explore',self.id.to_s)
    FileUtils.rm_r(dir) if File.exists?(dir)
  end
  
  def result_file(tsv = false)
    return tsv ? Rails.root.join('data','explore',self.id.to_s,'result.tsv') : Rails.root.join('data','explore',self.id.to_s,'result.csv')
  end
  
  # Generate filename for download
  def generate_filename
    filename = self.page+"_"+view_to_path(view)
    if !patt.eql?('[]')
      filename = filename+'_p='+patt.gsub(/\]\[/,' ').gsub(/\[*(word|lemma|pos|phonetic)=\"/,'').gsub(/\"\]*/,'')
    end
    filename = filename+'_w='+within if !within.eql?('document')
    filename = filename+'_f='+filter if !filter.blank?
    filename = filename+'_g='+group if !group.blank?
    return filename
  end
  
  def to_xml
    hash = { explore: { query: { page: self.page, patt: self.patt, within: self.within, view: self.view, listtype: self.listtype, offset: self.offset, number: self.number } } }
    hash[:explore][:query][:gap_values_tsv] = self.group unless self.gap_values_tsv.blank?
    hash[:explore][:query][:group] = self.group unless self.group.blank?
    hash[:explore][:query][:sample] = self.sample unless self.sample.blank?
    hash[:explore][:query][:samplenum] = self.samplenum unless self.samplenum.blank?
    hash[:explore][:query][:sampleseed] = self.sampleseed unless self.sampleseed.blank?
    hash[:explore][:filters] = self.filter unless self.filter.blank?
    return hash.to_xml(:root => 'whitelab')
  end
  
  def self.find_from_params(page, user, params)
    query = user.explore_queries.find(params[:id].to_i) if params.has_key?(:id)
    return query ? query : WhitelabQuery.find_from_params(Explore::Query, page, user.id, params)
  end
  
  def self.create_hash(user_id, page, params)
    hash = {
      :user_id => user_id, 
      :within => params.has_key?(:within) ? params[:within] : 'document', 
      :filter => params.has_key?(:filter) ? params[:filter] : nil, 
      :listtype => params.has_key?(:listtype) ? params[:listtype] : 'word', 
      :ngram_size => params.has_key?(:size) ? params[:size].to_i : nil,
      :sample => params.has_key?(:sample) && !params[:sample].blank? ? params[:sample].to_i : nil,
      :samplenum => params.has_key?(:samplenum) && !params[:samplenum].blank? ? params[:samplenum].to_i : nil,
      :sampleseed => params.has_key?(:sampleseed) && !params[:sampleseed].blank? ? params[:sampleseed].to_i : nil,
      :input_page => page,
      :view => 8,
      :group => "hit:#{params[:listtype] || 'word'}",
      :status => 0
    }
    if page.eql?('statistics')
      hash[:patt] = "[]"
    elsif page.eql?('ngrams')
      hash[:patt] = params[:patt] if params.has_key?(:patt) && !params[:patt].blank?
      hash[:gap_values_tsv] = params[:gap_values_tsv] if params.has_key?(:gap_values_tsv) && !params[:gap_values_tsv].blank?
    end
    return hash
  end
  
  def self.where_data(user_id, page, params)
    if page.eql?('statistics')
      return {
        :user_id => user_id,
        :filter => params[:filter],
        :listtype => params.has_key?(:listtype) ? params[:listtype] : 'word',
        :input_page => page,
        :sample => params.has_key?(:sample) && !params[:sample].blank? ? params[:sample].to_i : nil,
        :samplenum => params.has_key?(:samplenum) && !params[:samplenum].blank? ? params[:samplenum].to_i : nil,
        :sampleseed => params.has_key?(:sampleseed) && !params[:sampleseed].blank? ? params[:sampleseed].to_i : nil
      }
    elsif page.eql?('ngrams')
      return {
        :user_id => user_id,
        :patt => params.has_key?(:patt) ? URI.unescape(params[:patt]) : nil,
        :filter => params[:filter],
        :listtype => params.has_key?(:listtype) ? params[:listtype] : 'word',
        :input_page => page,
        :sample => params.has_key?(:sample) && !params[:sample].blank? ? params[:sample].to_i : nil,
        :samplenum => params.has_key?(:samplenum) && !params[:samplenum].blank? ? params[:samplenum].to_i : nil,
        :sampleseed => params.has_key?(:sampleseed) && !params[:sampleseed].blank? ? params[:sampleseed].to_i : nil,
        :gap_values_tsv => params.has_key?(:gap_values_tsv) && !params[:gap_values_tsv].blank? ? params[:gap_values_tsv] : nil
      }
    end
  end
  
  def self.query_xml_to_url_params(query_xml)
    arr = []
    page = query_xml.css("page").any? ? query_xml.at_css("page").content : nil
    return ["No page tag found in query!"], true unless page
    return ["Invalid page value!"], true unless ["ngrams","statistics"].include?(page)
    if page.eql?("ngrams") && query_xml.css("patt tokens token").any?
      arr << "patt=#{URI.escape(self.get_tokens_from_xml(query_xml.css("patt > tokens")), Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    elsif page.eql?("ngrams") && query_xml.at_css("patt").content.length > 0
      arr << "patt=#{URI.escape(query_xml.at_css("patt").content, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    elsif page.eql?("ngrams")
      return ["Invalid patt value!"], true
    end
    if query_xml.css("group context").any?
      group, error = self.get_complex_group_from_xml(query_xml)
      return [group], true if error
      arr << "group=#{URI.escape(group, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    elsif query_xml.css("group").any? && query_xml.at_css("group").content.length > 0
      group = query_xml.at_css("group").content
      arr << "group=#{URI.escape(group, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    end
    ["within","listtype","size","offset","sample","samplenum","sampleseed","gap_values_tsv"].each do |param|
      arr << "#{param}=#{URI.escape(query_xml.at_css(param).content, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}" if query_xml.css(param).any?
    end
    arr << "view=#{query_xml.at_css("view").content}" if query_xml.css("view").any? && !arr.select{|str| str.start_with?("view=") }.any?
    arr << "number=#{query_xml.at_css("number").content}" if query_xml.css("number").any? && [50,100,200].include?(query_xml.at_css("number").content.to_i)
    return arr, false
  end
  
  def self.get_complex_group_from_xml(query_xml)
    group = query_xml.at_css("group context").content
    group = query_xml.css("group type").any? ? "#{group}:#{query_xml.at_css("group type").content}" : "word"
    group = query_xml.css("group case").any? ? "#{group}:#{query_xml.at_css("group case").content}" : "s"
    return group, false
  end
  
  def is_changed?(page, params)
    if [page,self.page].include?('statistics')
      return true if attribute_is_changed?(patt,"[]")
    elsif [page,self.page].include?('ngrams')
      return true if attribute_is_changed?(patt,params.has_key?(:patt) && !params[:patt].blank? ? params[:patt] : nil)
    end
    return true if attribute_is_changed?(within,params.has_key?(:within) ? params[:within] : 'document')
    return true if attribute_is_changed?(filter,params[:filter])
    return true if attribute_is_changed?(listtype,params.has_key?(:listtype) ? params[:listtype] : 'word')
    return true if attribute_is_changed?(ngram_size,params[:size])
    return true if attribute_is_changed?(input_page,page)
    return false
  end
  
  def update_from_params(params)
    new_query = self
    new_query.waiting! if new_query.failed?
    if attribute_is_changed?(self.view,params[:view].to_i)
      if !new_query.not_exported?
        new_query = self.dup
        new_query.not_exported!
      end
      new_query.update_attributes({ :view => params[:view].to_i, :group => nil, :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
      if new_query.view == 8 && new_query.group.blank?
        new_query.update_attribute(:group, "hit:#{self.listtype || 'word'}")
      end
    elsif attribute_is_changed?(new_query.group,params[:group])
      if !new_query.not_exported?
        new_query = self.dup
        new_query.not_exported!
      end
      new_query.update_attributes({ :group => params[:group], :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    end
    changed = new_query.attributes_are_changed?(params.slice(:order, :sort, :number, :offset))
    if changed
      new_query.waiting!
      new_query.order = params[:order] if attribute_is_changed?(self.order,params[:order])
      new_query.sort = params[:sort] if attribute_is_changed?(self.sort,params[:sort])
      new_query.number = params[:number].to_i if attribute_is_changed?(self.number,params[:number].to_i)
      new_query.offset = params[:offset].to_i if attribute_is_changed?(self.offset,params[:offset].to_i)
      new_query.save!
    end
    return new_query
  end
  
end
