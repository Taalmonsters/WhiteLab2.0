# Module for Explore Queries, includes WhitelabQuery
class Explore::Query < ActiveRecord::Base
  include WhitelabQuery
  
  before_destroy :delete_export_files
  
  def delete_export_files
    dir = Rails.root.join('data','explore',self.id.to_s)
    FileUtils.rm_r(dir) if File.exists?(dir)
  end
  
  def result_file
    return Rails.root.join('data','explore',self.id.to_s,'result.csv')
  end
  
  def metadata_file
    return Rails.root.join('data','explore',self.id.to_s,'metadata.xml')
  end
  
  def metadata
    return {
      :page => self.input_page,
      :patt => self.patt,
      :within => self.within,
      :filter => self.filter,
      :view => self.view,
      :group => self.group,
      :listtype => self.listtype,
      :size => self.size
    }.to_xml(:root => 'explore_query')
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
      :ngram_size => params.has_key?(:size) ? params[:size] : nil, 
      :input_page => page,
      :view => 8,
      :group => "hit:#{params[:listtype] || 'word'}",
      :status => 0
    }
    if page.eql?('statistics')
      hash[:patt] = "[]"
    elsif page.eql?('ngrams') && params.has_key?(:patt) && !params[:patt].blank?
      hash[:patt] = params[:patt]
    end
    return hash
  end
  
  def self.where_data(user_id, page, params)
    if page.eql?('statistics')
      return {
        :user_id => user_id,
        :filter => params[:filter],
        :listtype => params.has_key?(:listtype) ? params[:listtype] : 'word',
        :input_page => page
      }
    elsif page.eql?('ngrams')
      return {
        :user_id => user_id,
        :patt => params[:patt],
        :filter => params[:filter],
        :listtype => params.has_key?(:listtype) ? params[:listtype] : 'word',
        :input_page => page
      }
    end
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
    self.waiting! if self.failed?
    if attribute_is_changed?(self.view,params[:view].to_i)
      self.update_attributes({ :view => params[:view].to_i, :group => nil, :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    elsif attribute_is_changed?(self.group,params[:group])
      self.update_attributes({ :group => params[:group], :order => nil, :sort => nil, :offset => 0, :group_count => nil, :status => 0 })
    end
    changed = attributes_are_changed?(params.slice(:order, :sort, :number, :offset))
    if changed
      self.waiting!
      self.order = params[:order] if attribute_is_changed?(self.order,params[:order])
      self.sort = params[:sort] if attribute_is_changed?(self.sort,params[:sort])
      self.number = params[:number].to_i if attribute_is_changed?(self.number,params[:number].to_i)
      self.offset = params[:offset].to_i if attribute_is_changed?(self.offset,params[:offset].to_i)
      self.save!
    end
    return self
  end
  
end
