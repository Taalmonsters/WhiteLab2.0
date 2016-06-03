# Module for Export Queries, inherits from WhitelabQuery
class Export::Query < ActiveRecord::Base
  include WhitelabQuery
  include DataFormatHelper
  
  # Generate filename for download
  def generate_filename
    filename = view_to_path(view)
    if patt.eql?('[word=".*"]')
      filename = filename+'_p=empty'
    else
      filename = filename+'_p='+patt.gsub(/\]\[/,' ').gsub(/\[*(word|lemma|pos|phonetic)=\"/,'').gsub(/\"\]*/,'')
    end
    filename = filename+'_w='+within if !within.eql?('document')
    filename = filename+'_f='+filter if !filter.blank?
    filename = filename+'_g='+group if !group.blank?
    return filename
  end
end
