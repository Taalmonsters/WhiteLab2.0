require 'net/http'
require 'uri'

# Main backend helper module.
module BackendHelper
  
  def execute_query(data)
    resp = nil
    if data.has_key?(:method) && data[:method].eql?('post')
      if data.has_key?(:query)
        resp = post_query(data)
      else
        resp = post_headers(data)
      end
    else
      if data.has_key?(:query)
        resp = get_query(data)
      else
        resp = get_headers(data)
      end
    end
    if WhitelabBackend.instance.get_backend_type.eql?('neo4j')
      return resp.parsed_response
    else
      return resp
    end
  end
  
  def get_headers(data)
    HTTParty.get(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :headers => data[:headers]
    )
  end
  
  def get_number(query, docpid, number)
    n = query.number
    if !number.blank?
      n = number
    elsif !docpid.blank?
      n = 50
    end
    return n
  end
  
  def get_offset(query, docpid, offset)
    o = query.offset
    if !offset.blank?
      o = offset
    elsif !docpid.blank?
      o = 0
    end
    return o
  end
  
  def get_query(data)
    HTTParty.get(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :query => data[:query],
      :headers => data[:headers]
    )
  end
  
  def get_response_stream(data, target)
    uri = URI(data[:url])
    uri.query = URI.encode_www_form(data[:query])
    
    request = nil
    if data.has_key?(:method) && data[:method].eql?('post')
      request = Net::HTTP::Post.new(uri.path)
    else
      request = Net::HTTP::Get.new(uri.path)
    end
    @@HEADERS.each do |key, value|
      request.add_field(key, value)
    end

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request request do |response|
        open target, 'w' do |io|
          response.read_body do |chunk|
            io.write chunk
          end
        end
      end
    end
  end
  
  def get_view(query, docpid, view)
    v = query.view
    if !view.blank?
      v = view
    elsif !docpid.blank?
      v = 1
    end
    return v
  end
  
  def get_within(query, default)
    w = default
    if query.has_attribute?(:within) && !query.within.blank?
      w = query.within
    end
    return w
  end
  
  def post_headers(data)
    HTTParty.post(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :headers => data[:headers]
    )
  end
  
  def post_query(data)
    HTTParty.post(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :query => data[:query],
      :headers => data[:headers]
    )
  end
  
  # Load options for grouping by metadatum
  def get_metadata_group_options(groups, namespace)
    DOCUMENT_METADATA.each do |group, keys|
      keys.each do |key, data|
        unless key.include?("\.") || (namespace.eql?('explore') && data.has_key?('explorable') && data['explorable'].eql?('false')) || 
          (namespace.eql?('search') && data.has_key?('searchable') && data['searchable'].eql?('false'))
          tr_group = group_translation_key(data['group'])
          groups[tr_group] = [] unless groups.has_key?(tr_group)
          groups[tr_group] << [key_translation_key(key), data['label']]
        end
      end
    end
    groups
  end
  
  # Load paginated list of metadata in index
  def get_metadata(number, offset, sort, order)
    fields = []
    DOCUMENT_METADATA.each do |group, gdata|
      gdata.keys.select{|k| !k.include?("\.") }.each{|k| fields << {'group' => group, 'key' => k} }
    end
    data = fields.uniq[offset..offset+number].map{|f| reformat_metadatum(f['group'], f['key']) }
    return { 'total' => fields.size, 'metadata' => data }
  end
  
  # Load metadatum properties by label
  def get_metadatum_by_label(label)
    group, key = get_metadatum_group_and_key_from_label(label)
    DOCUMENT_METADATA[group][key]
  end
  
  def get_metadatum_group_and_key_from_label(label)
    if label.start_with?("Corpus_")
      return "Corpus", label.sub(/^Corpus_/,"")
    elsif label.start_with?("Collection_")
      return "Collection", label.sub(/^Collection_/,"")
    else
      return "Metadata", label
    end
  end
  
  def reformat_metadatum(group, key)
    obj = DOCUMENT_METADATA[group][key]
    unless obj.keys.select{|k| k.start_with?('document_count_')}.any?
      metadata = load_metadata(group, key)
      metadata.each do |value, docs|
        docs.each do |i|
          doc = DOCUMENT_DATA[DOCUMENT_DATA.keys[i]]
          obj['document_count_'+doc['corpus']] = 0 unless obj.has_key?('document_count_'+doc['corpus'])
          obj['document_count_'+doc['corpus']] += 1
        end
      end
      save_metadata
    end
    return obj
  end
  
  def reformat_metadatum_values(group, key, metadata, values)
    data = []
    values.each do |value|
      obj = { 'value' => value, 'document_count' => metadata[value].size, 'corpus_counts' => { 'corpora' => [], 'counts' => [] } }
      metadata[value].each do |i|
        doc = DOCUMENT_DATA[DOCUMENT_DATA.keys[i]]
        unless obj['corpus_counts']['corpora'].include?(doc['corpus'])
          obj['corpus_counts']['corpora'] << doc['corpus']
          obj['corpus_counts']['counts'] << 0
        end
        obj['corpus_counts']['counts'][obj['corpus_counts']['corpora'].index(doc['corpus'])] += 1
      end
      data << obj
    end
    data
  end
  
  # Load metadatum values by label
  def get_metadatum_values_by_label(number, offset, sort, order, label)
    group, key = get_metadatum_group_and_key_from_label(label)
    get_metadatum_values_by_group_and_key(number, offset, sort, order, group, key)
  end
  
  # Load metadatum values by group and key
  def get_metadatum_values_by_group_and_key(number, offset, sort, order, group, key)
    metadata = load_metadata(group, key)
    reformat_metadatum_values(group, key, metadata, number == 0 ? metadata.keys : metadata.keys[offset..offset+number])
  end
  
  def get_pos_heads(number, offset, sort, order)
    data = ['ADJ', 'BW', 'LET', 'LID', 'N', 'SPEC', 'TW', 'TSW', 'VG', 'VNW', 'VZ', 'WW']
    ph = {
      "total" => data.size,
      "number" => number,
      "offset" => offset,
      "sort" => sort,
      "order" => order,
      "pos_heads" => []
    }
    data.each do |group|
      ph["pos_heads"] << {
        "label" => group,
        "token_count" => 0
      }
    end
    ph
  end
  
  def update_metadatum(label, updates)
    metadatum = get_metadatum_by_label(label)
    updates.each do |k,v|
      metadatum[k] = v
    end
    save_metadata
  end
  
end