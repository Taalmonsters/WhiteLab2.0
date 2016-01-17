# Module for Export Queries
class ExportQuery < ActiveRecord::Base
  include DataFormatHelper
  belongs_to :user
  has_and_belongs_to_many :query_results
  
  # Find or create new ExportQuery from QueryResult
  def self.get_current_query(user_id, page, query_result)
    number = EXPORT_LIMIT
    if query_result.view == 1 && query_result.hit_count < number
      number = query_result.hit_count
    elsif query_result.view == 2 && query_result.document_count < number
      number = query_result.document_count
    elsif [8, 16].include?(query_result.view) && query_result.group_count < number
      number = query_result.group_count
    end
    
    export_query = ExportQuery.where({ 
      :user_id => user_id, 
      :input_page => page, 
      :patt => query_result.patt,
      :filter => query_result.filter,
      :within => query_result.within,
      :view => query_result.view,
      :group => query_result.group,
      :sort => query_result.sort,
      :order => query_result.order,
      :offset => 0,
      :number => number
    }).first
    
    if export_query.blank?
      export_query = ExportQuery.where({ 
        :input_page => page, 
        :patt => query_result.patt,
        :filter => query_result.filter,
        :within => query_result.within,
        :view => query_result.view,
        :group => query_result.group,
        :sort => query_result.sort,
        :order => query_result.order,
        :offset => 0,
        :number => number
      }).order("status DESC, updated_at DESC").first
      if !export_query.blank?
        export_query = export_query.dup
        export_query.update_attribute(:user_id,user_id)
      end
    end
    
    if export_query.blank?
      export_query = ExportQuery.create({ 
        :user_id => user_id, 
        :input_page => page, 
        :patt => query_result.patt,
        :filter => query_result.filter,
        :within => query_result.within,
        :view => query_result.view,
        :group => query_result.group,
        :sort => query_result.sort,
        :order => query_result.order,
        :offset => 0,
        :number => number
      })
      export_query.run
    end
    
    return export_query
  end
  
  # Run export in increments
  def run
    Thread.new do
      self.update_attribute(:status, 1)
      o = self.offset
      results = []
      while o < self.number
        threads = []
        [o].each do |oo|
          if oo < self.number
            threads << Thread.new do
              begin
                query_result = QueryResult.get_current_query_result({
                  "patt" => self.patt, 
                  "filter" => self.filter, 
                  "within" => self.within, 
                  "view" => self.view, 
                  "group" => self.group, 
                  "sort" => self.sort, 
                  "order" => self.order, 
                  "offset" => oo, 
                  "number" => 1000
                })
              rescue => exception
                puts exception.backtrace
                raise exception
              end
              if query_result.is_new
                query_result.run(false, oo, 1000)
              end
              Thread.current[:output] = { 'result' => query_result }
            end
          end
        end
        threads.each do |t|
          t.join
          if t[:output].has_key?('result')
            begin
              results << t[:output]['result']
            rescue => exception
              puts exception.backtrace
              raise exception
            end
          end
        end
        o = o + 1000
      end
      self.query_results = results
      self.update_attribute(:status, 10)
    end
  end
  
  # Get ExportQuery status string
  def text_status
    if self.status == 0
      'Waiting'
    elsif self.status == 1
      'Running'
    elsif self.status == 10
      'Finished'
    else
      'Error'
    end
  end
  
  # Generate filename for download
  def generate_filename
    filename = view_to_path(self.view)
    if self.patt.eql?('[word=".*"]')
      filename = filename+'_p=empty'
    else
      patt = self.patt.gsub(/\]\[/,' ').gsub(/\[*(word|lemma|pos|phonetic)=\"/,'').gsub(/\"\]*/,'')
      filename = filename+'_p='+patt
    end
    if !self.filter.blank?
      filename = filename+'_f='+self.filter
    end
    if !self.group.blank?
      filename = filename+'_g='+self.group
    end
    if !self.within.eql?('document')
      filename = filename+'_w='+self.within
    end
    filename
  end
  
  def page
    self.input_page
  end
end
