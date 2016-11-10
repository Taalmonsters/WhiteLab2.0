# Module for Search Queries, includes WhitelabQuery
class Search::Query < ActiveRecord::Base
  include WhitelabQuery
  
  before_destroy :delete_export_files
  
  def delete_export_files
    dir = Rails.root.join('data','search',self.id.to_s)
    FileUtils.rm_r(dir) if File.exists?(dir)
  end
  
  def result_file
    return Rails.root.join('data','search',self.id.to_s,'result.csv')
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
  
  def self.find_from_params(page, user, params)
    if params.has_key?(:id)
      query = user.search_queries.find(params[:id].to_i)
      query = nil if query && query.is_changed?(page, params)
    end
    return query ? query : WhitelabQuery.find_from_params(Search::Query, page, user.id, params)
  end
  
  def self.create_hash(user_id, page, params)
    return {
      :user_id => user_id, 
      :patt => params[:patt], 
      :within => params.has_key?(:within) ? params[:within] : 'document', 
      :filter => params.has_key?(:filter) && !params[:filter].blank? ? params[:filter] : nil, 
      :group => params.has_key?(:group) ? params[:group] : nil, 
      :view => params.has_key?(:view) ? params[:view].to_i : 1, 
      :input_page => page,
      :status => 0
    }
  end
  
  def self.where_data(user_id, page, params)
    return {
      :user_id => user_id,
      :patt => params[:patt],
      :within => params.has_key?(:within) ? params[:within] : 'document',
      :filter => params.has_key?(:filter) && !params[:filter].blank? ? params[:filter] : nil
    }
  end
  
  def add_hits_group(hits_group)
    hits_group.gsub!(/([\(\)\[\]\'\"\?\!])/){|s| "\\"+s}
    qgroup_parts = group.split('_')
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
    elsif self.group.start_with?('left')
      self.patt = "[#{context_group_label}=\"(?c)#{hits_group}\"]#{self.patt}"
    elsif self.group.start_with?('right')
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
