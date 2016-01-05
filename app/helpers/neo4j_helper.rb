# Neo4j backend helper methods.
module Neo4jHelper
  include DataFormatHelper
  require "base64"
  
  # Run CQL query on server for set amount of iterations. Returns a report of the absolute and average duration at each interval.
  def run_benchmark_test(cql,iterations)
    url = 'http://localhost:7474/whitelab/admin/test/query'
    HTTParty.post(url, timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "query" => cql, 
        "iter" => iterations
      },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
    )
  end
  
  # Get node containing total counts for all node labels in index
  def get_counter_node
    resp = HTTParty.get('http://localhost:7474/db/data/label/NodeCounter/nodes', timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    
    properties = HTTParty.get(resp[0]["properties"], timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    return properties.parsed_response.except('status').sort
  end
  
  # Update metadatum in index
  def update_metadatum(label, updates)
    set = []
    updates.each do |key, value|
      HTTParty.post('http://localhost:7474/whitelab/search/metadata/'+label+'/update', timeout: NEO4J_TIMEOUT_SECONDS,
        :query => { "property" => key, 
                   "value" => value.to_s
                 },
        :headers => { 'Content-Type' => 'application/json',
                      'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    end
  end
  
  # Load list of corpus titles in index
  def get_corpus_titles
    corpora = []
    resp = HTTParty.get('http://localhost:7474/db/data/label/Corpus/nodes', timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    
    resp.parsed_response.each do |node|
      label_resp = HTTParty.get(node["properties"]+"/title", timeout: NEO4J_TIMEOUT_SECONDS,
        :headers => { 'Content-Type' => 'application/json',
                      'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
      corpora << label_resp.parsed_response
    end
    corpora
  end
  
  # Load list of corpus labels in index
  def get_corpus_labels
    corpora = []
    resp = HTTParty.get('http://localhost:7474/db/data/label/Corpus/nodes', timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    
    resp.parsed_response.each do |node|
      label_resp = HTTParty.get(node["properties"]+"/label", timeout: NEO4J_TIMEOUT_SECONDS,
        :headers => { 'Content-Type' => 'application/json',
                      'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
      corpora << label_resp.parsed_response
    end
    
    corpora
  end
  
  # Load paginated list of metadata in index
  def get_metadata(number, offset, sort, order)
    resp = HTTParty.get('http://localhost:7474/whitelab/search/metadata', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "number" => number, 
                 "offset" => offset,
                 "sort" => sort, 
                 "order" => order
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  # Load metadatum properties by label
  def get_metadatum_by_label(label)
    p "***INFO - get_metadatum_by_label("+label+")"
    resp = HTTParty.get('http://localhost:7474/whitelab/search/metadata/'+label, timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  # Load metadatum values by label
  def get_metadatum_values_by_label(number, offset, sort, order, label)
    p "***INFO - get_metadatum_values_by_label("+label+")"
    resp = HTTParty.get('http://localhost:7474/whitelab/search/metadata/'+label+'/values', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "number" => number, 
                 "offset" => offset,
                 "sort" => sort, 
                 "order" => order
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  def get_group_options(v)
    groups = {}
    if v == 8
      groups['hit'] = []
      groups['left'] = []
      groups['right'] = []
      ['hit'].each do |position|
        ['text','lemma','pos','phonetic'].each do |annotation|
          groups['hit'] << [annotation, position+'_'+annotation]
        end
      end
      ['left','right'].each do |position|
        ['text','lemma','pos','phonetic'].each do |annotation|
          groups[position] << [annotation, annotation+'_'+position]
        end
      end
    end
    groups[translate(:"data_labels.keys.corpus").capitalize] = []
    groups[translate(:"data_labels.keys.corpus").capitalize] << [translate(:"data_labels.keys.corpus").capitalize+' '+translate(:"navigation.keys.title").capitalize, 'Corpus_title']
    groups[translate(:"data_labels.keys.collection").capitalize] = []
    groups[translate(:"data_labels.keys.collection").capitalize] << [translate(:"data_labels.keys.collection").capitalize+' '+translate(:"navigation.keys.title").capitalize, 'Collection_title']
    metadata_nodes = HTTParty.get('http://localhost:7474/db/data/label/Metadatum/nodes', timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    
    metadata_nodes.parsed_response.each do |node|
      node_properties = HTTParty.get(node["properties"], timeout: NEO4J_TIMEOUT_SECONDS,
        :headers => { 'Content-Type' => 'application/json',
                      'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
      node_properties = node_properties.parsed_response
      if !node_properties.has_key?('searchable') || node_properties['searchable'].blank? || node_properties['searchable'] == true
        if !groups.has_key?(translate(group_translation_key(node_properties['group'])).capitalize)
          groups[translate(group_translation_key(node_properties['group'])).capitalize] = []
        end
        groups[translate(group_translation_key(node_properties['group'])).capitalize] << [translate(key_translation_key(node_properties['key'])), node_properties['group']+'_'+node_properties['key']]
      end
    end
    
    groups
  end
  
  def get_hits_in_group(query,group,offset,number)
    url = 'http://localhost:7474/whitelab/search/hits'
    filter = query.filter
    pattern = query.patt
    if query.group.start_with?('hit')
      pattern = '['+group_to_label(query.group.split('_')[1])+'="(?c)'+group+'"]'
    elsif query.group.end_with?('left')
      pattern = '['+group_to_label(query.group.split('_')[0])+'="(?c)'+group+'"]'+pattern
    elsif query.group.end_with?('right')
      pattern = pattern+'['+group_to_label(query.group.split('_')[0])+'="(?c)'+group+'"]'
    elsif filter.blank?
      filter = "("+query.group+"=\""+group+"\")"
    else
      filter = filter+"AND("+query.group+"=\""+group+"\")"
    end
    
    HTTParty.post(url, timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "pattern" => pattern, 
        "filter" => filter, 
        "within" => query.within, 
        "number" => number, 
        "offset" => offset
      },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
    )
  end
  
  def get_docs_in_group(query,group,offset,number)
    url = 'http://localhost:7474/whitelab/search/docs'
    filter = query.filter
    if filter.blank?
      filter = "("+query.group+"=\""+group+"\")"
    else
      filter = filter+"AND("+query.group+"=\""+group+"\")"
    end
    HTTParty.post(url, timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "pattern" => query.patt, 
        "filter" => filter, 
        "within" => query.within, 
        "number" => number, 
        "offset" => offset
      },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
    )
  end
  
  def get_search_results_for_query(query, docpid, offset, number)
    v = query.view
    o = query.offset
    n = query.number
    if !docpid.blank?
      v = 1
      o = 0
    elsif !offset.blank?
      o = offset
    end
    if !number.blank?
      n = number
    end
    url = 'http://localhost:7474/whitelab/search/'+view_to_path(v)
    within = 'document'
    if query.has_attribute?(:within) && !query.within.blank?
      within = query.within
    end
    if [8,16].include?(v)
      data = HTTParty.post(url, timeout: NEO4J_TIMEOUT_SECONDS,
        :query => {  
          "pattern" => query.patt, 
          "filter" => query.filter, 
          "within" => within, 
          "number" => n, 
          "offset" => o,
          "docpid" => docpid,
          "group" => query.group
        },
        :headers => { 'Content-Type' => 'application/json',
                      'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
      )
    elsif v == 4
      data = HTTParty.get('http://localhost:7474/whitelab/search/metadata/content', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "filter" => query.filter,
                 "pattern" => query.patt,
                 "offset" => o, 
                 "number" => n
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    else
      data = HTTParty.post(url, timeout: NEO4J_TIMEOUT_SECONDS,
        :query => {  
          "pattern" => query.patt, 
          "filter" => query.filter, 
          "within" => within, 
          "number" => n, 
          "offset" => o,
          "docpid" => docpid
        },
        :headers => { 'Content-Type' => 'application/json',
                      'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
      )
    end
    data['results'] = data[view_to_path(v)]
    data.except(view_to_path(v))
  end
  
  def get_search_result_counts_for_query(query, docpid, v, n, o)
    view = v
    if view.blank?
      view = query.view
    end
    url = 'http://localhost:7474/whitelab/search/'+view_to_path(view)+'/count'
    within = 'document'
    if query.has_attribute?(:within) && !query.within.blank?
      within = query.within
    end
    number = n
    if number.blank?
      number = query.number
    end
    offset = o
    if offset.blank?
      offset = query.offset
    end
    if [8,16].include?(query.view)
      HTTParty.post(url, timeout: NEO4J_TIMEOUT_SECONDS,
        :query => {  
          "pattern" => query.patt, 
          "filter" => query.filter, 
          "within" => within, 
          "number" => number, 
          "offset" => offset,
          "docpid" => docpid,
          "group" => query.group
        },
        :headers => { 'Content-Type' => 'application/json',
                      'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
      )
    else
      HTTParty.post(url, timeout: NEO4J_TIMEOUT_SECONDS,
        :query => {  
          "pattern" => query.patt, 
          "filter" => query.filter, 
          "within" => within, 
          "number" => number, 
          "offset" => offset,
          "docpid" => docpid
        },
        :headers => { 'Content-Type' => 'application/json',
                      'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
      )
    end
  end
  
  def get_kwic(docpid, first_index, last_index, size)
    HTTParty.get('http://localhost:7474/whitelab/search/hits/kwic', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "docpid" => docpid, 
                 "first_index" => first_index, 
                 "last_index" => last_index, 
                 "size" => size 
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
  end
  
  def get_filtered_content(query)
    data = HTTParty.get('http://localhost:7474/whitelab/search/metadata/content', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "filter" => query.filter,
                 "pattern" => query.patt,
                 "offset" => query.offset, 
                 "number" => query.number
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    data.parsed_response
  end
  
  def get_document_content(xmlid, patt, offset, number)
    data = HTTParty.get('http://localhost:7474/whitelab/search/docs/'+xmlid+'/content', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "offset" => offset, 
                 "number" => number,
                 "pattern" => patt
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    p data
    data = data.parsed_response
    return data['content'][0]
  end
  
  def get_document_metadata(xmlid)
    data = HTTParty.get('http://localhost:7474/whitelab/search/docs/'+xmlid+'/metadata', timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    data['metadata']
  end
  
  def get_document_statistics(xmlid)
    data = HTTParty.get('http://localhost:7474/whitelab/search/docs/'+xmlid+'/statistics', timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    data['statistics']
  end
  
  def get_metadatum_values_by_group_and_key(number, offset, sort, order, group, key, count)
    p "***INFO - get_metadatum_values_by_group_and_key("+number.to_s+", "+offset.to_s+", "+sort+", "+order+", "+group+", "+key+")"
    HTTParty.get('http://localhost:7474/whitelab/search/metadata/'+group+'/'+key+'/values', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "number" => number, 
                 "offset" => offset,
                 "sort" => sort, 
                 "order" => order,
                 "count" => count
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
  end
  
  def get_pos_tags(number, offset, sort, order)
    resp = HTTParty.get('http://localhost:7474/whitelab/search/pos/tags', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "number" => number, 
                 "offset" => offset,
                 "sort" => sort, 
                 "order" => order
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  def get_pos_heads(number, offset, sort, order)
    p "***INFO - get_pos_heads"
    resp = HTTParty.get('http://localhost:7474/whitelab/search/pos/heads', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "number" => number, 
                 "offset" => offset,
                 "sort" => sort, 
                 "order" => order
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  def get_pos_tag_by_label(label)
    resp = HTTParty.get('http://localhost:7474/whitelab/search/pos/tags/'+label, timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  def get_pos_head_by_label(label)
    resp = HTTParty.get('http://localhost:7474/whitelab/search/pos/heads/'+label, timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  def get_pos_tag_features_by_label(label)
    resp = HTTParty.get('http://localhost:7474/whitelab/search/pos/tags/'+label+'/features', timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  def get_pos_head_features_by_label(label)
    resp = HTTParty.get('http://localhost:7474/whitelab/search/pos/heads/'+label+'/features', timeout: NEO4J_TIMEOUT_SECONDS,
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
  def get_pos_tag_types_by_label(number, offset, sort, order, label)
    resp = HTTParty.get('http://localhost:7474/whitelab/search/pos/tags/'+label+'/word_types', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "number" => number, 
                 "offset" => offset,
                 "sort" => sort,
                 "order" => order
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response['word_types']
  end
  
  def get_pos_head_tags_by_label(number, offset, sort, order, label)
    resp = HTTParty.get('http://localhost:7474/whitelab/search/pos/heads/'+label+'/tags', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "number" => number, 
                 "offset" => offset,
                 "sort" => sort,
                 "order" => order
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    resp.parsed_response
  end
  
end