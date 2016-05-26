# Neo4J backend helper methods.
module Neo4jHelper
  
  include BackendHelper
  include DataFormatHelper
  
  def headers
    { 'Content-Type' => 'application/json', 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
  end
  
  def count_grouped_results(key, count_obj)
    get_grouped_results("#{key}/count", count_obj)
  end
  
  def count_results(key, count_obj)
    get_results("#{key}/count", count_obj)
  end
  
  def db_type
    'neo4j'
  end
  
  # Load list of collection titles in index
  def get_collection_titles
    get_titles('Collection', 'title')
  end
  
  # Load list of corpus titles in index
  def get_corpus_titles
    get_titles('Corpus', 'label')
  end
  
  def get_titles(key, field_key)
    titles = []
    resp = execute_query({
      :url => "#{backend_url}db/data/label/#{key}/nodes",
      :headers => headers
    })
    resp.each do |node|
      titles << get_node_label(node, field_key)
    end
    titles
  end
  
  def get_node_label(node, field_key = 'label')
    execute_query({
      :url => "#{node['properties']}/#{field_key}",
      :headers => headers
    })
  end
  
  # Get node containing total counts for all node labels in index
  def get_counter_node
    resp = execute_query({
      :url => backend_url+'db/data/label/NodeCounter/nodes',
      :headers => headers
    })
    properties = execute_query({
      :url => resp[0]["properties"],
      :headers => headers
    })
    return properties.except('status').sort
  end
  
  def get_docs_in_group(query,group,offset,number)
    filter = get_grouped_filter(query.group, group)
    execute_query({
      :url => backend_url+'whitelab/search/docs',
      :query => { 
        "pattern" => pattern, 
        "filter" => filter, 
        "within" => query.within, 
        "number" => number, 
        "offset" => offset
      },
      :headers => headers
    })
  end
  
  def get_document_content(xmlid, patt, offset, number)
    data = execute_query({
      :url => backend_url+'whitelab/search/docs/'+xmlid+'/content',
      :query => { 
        "offset" => offset,
        "number" => number,
        "pattern" => patt
      },
      :headers => headers
    })
    # return data
    return data['content'][0]
  end
  
  def get_document_list
    data = `curl --header "Authorization: Basic bmVvNGo6Nzc0M21vbnN0ZXJzODE=" -H accept:application/json -H content-type:application/json -d '{"statements": [{ "statement": "MATCH (d:Document)<-[:HAS_DOCUMENT]->(cc:Collection) MATCH (cc)<-[:HAS_COLLECTION]-(c:Corpus) RETURN DISTINCT d.xmlid AS xmlid, d.token_count AS token_count, c.title AS corpus, cc.title AS collection;" }]}' http://localhost:7474/db/data/transaction/commit`;
    data = JSON.parse(data)
    docs = {}
    data["results"][0]["data"].each do |doc_row|
      doc = doc_row["row"]
      docs[doc[0]] = {"token_count" => doc[1], "corpus" => doc[2], "collection" => doc[3]}
    end
    docs
  end
  
  def get_document_metadata(xmlid)
    get_document_data(xmlid, 'metadata')
  end
  
  def get_document_statistics(xmlid)
    get_document_data(xmlid, 'statistics')
  end
  
  def get_document_data(xmlid, key)
    data = execute_query({
      :url => "#{backend_url}whitelab/search/docs/#{xmlid}/#{key}",
      :headers => headers
    })
    data[key]
  end
  
  def get_documents_for_filters(filters)
    filters = reformat_filters(filter)
    docs = []
    filters.each do |group, keys|
      keys.each do |key, values|
        ['positive','negative'].each do |set|
          sett = values[set]
          if sett.length > 0
            set_matches = get_filter_value_matches(set, { :group => group, :key => key }, sett)
            docs = docs.length == 0 ? set_matches : docs & set_matches
          end
        end
      end
    end
    return docs.uniq
  end
  
  def get_filter_value_matches(set, metadata_obj, value_set)
    matches = get_positive_filter_value_matches(metadata_obj, value_set) if set.eql?('positive')
    matches = get_negative_filter_value_matches(metadata_obj, value_set) if set.eql?('negative')
    return matches.any? ? matches.map{|doc_index| DOCUMENT_DATA.keys[doc_index.to_i] } : []
  end
  
  def get_filtered_content(query)
    execute_query({
      :url => backend_url+'whitelab/search/metadata/content',
      :query => { 
        "filter" => query.filter,
        "pattern" => query.patt,
        "offset" => query.offset,
        "number" => query.number
      },
      :headers => headers
    })
  end
  
  def get_grouped_results(path, search_obj)
    query = search_obj[:query]
    execute_query({
      :url => backend_url+'whitelab/search/'+path,
      :query => {  
        "pattern" => query.patt, 
        "filter" => query.filter, 
        "within" => search_obj[:within], 
        "number" => search_obj[:number], 
        "offset" => search_obj[:offset],
        "docpid" => search_obj.has_key?(:docpid) ? search_obj[:docpid] : nil,
        "group" => query.group
      },
      :headers => headers
    })
  end
  
  def get_grouped_filter(qgroup, group)
    if filter.blank?
      filter = "("+qgroup+"=\""+group+"\")"
    else
      filter = filter+"AND("+qgroup+"=\""+group+"\")"
    end
  end
  
  def get_hits_in_group(query,group,offset,number)
    filter = query.filter
    pattern = query.patt
    qgroup = query.group
    qgroup_parts = qgroup.split('_')
    context_group_label = group_to_label(qgroup_parts[0])
    if qgroup.start_with?('hit')
      pattern = '['+group_to_label(qgroup_parts[1])+'="(?c)'+group+'"]'
    elsif qgroup.end_with?('left')
      pattern = '['+context_group_label+'="(?c)'+group+'"]'+pattern
    elsif qgroup.end_with?('right')
      pattern = pattern+'['+context_group_label+'="(?c)'+group+'"]'
    else
      filter = get_grouped_filter(qgroup, group)
    end
    
    execute_query({
      :url => backend_url+'whitelab/search/hits',
      :query => { 
        "pattern" => pattern, 
        "filter" => filter, 
        "within" => query.within, 
        "number" => number, 
        "offset" => offset
      },
      :headers => headers
    })
  end
  
  def get_kwic(docpid, first_index, last_index, size = 50)
    execute_query({
      :url => backend_url+'whitelab/search/hits/kwic',
      :query => { 
        "docpid" => docpid,
        "first_index" => first_index,
        "last_index" => last_index,
        "size" => size
      },
      :headers => headers
    })
  end
  
  def get_metadata_from_server(number, offset, sort, order)
    get_metadata(number, offset, sort, order)
  end
  
  # Load paginated list of metadata in index
  def get_metadata(number, offset, sort, order)
    if number == 0
      execute_query({
        :url => backend_url+'db/data/label/Metadatum/nodes',
        :headers => headers
      })
    else
      execute_query({
        :url => backend_url+'whitelab/search/metadata',
        :query => {"number" => number,
                   "offset" => offset,
                   "sort" => sort, 
                   "order" => order },
        :headers => headers
      })
    end
  end
  
  # Load metadatum properties by label
  def get_metadatum_by_label(label)
    data = execute_query({
      :url => backend_url+'whitelab/search/metadata/'+label,
      :headers => headers
    })
    data[0]
  end
  
  # # Load options for grouping by metadatum
  # def get_metadata_group_options(groups)
    # metadata_nodes = execute_query({
      # :url => backend_url+'db/data/label/Metadatum/nodes',
      # :headers => headers
    # })
#     
    # metadata_nodes.each do |node|
      # node_properties = execute_query({
        # :url => node["properties"],
        # :headers => headers
      # })
      # if !node_properties.has_key?('searchable') || node_properties['searchable'].blank? || node_properties['searchable'] == true
        # if !groups.has_key?(group_translation_key(node_properties['group']))
          # groups[group_translation_key(node_properties['group'])] = []
        # end
        # groups[group_translation_key(node_properties['group'])] << [key_translation_key(node_properties['key']), node_properties['group']+'_'+node_properties['key']]
      # end
    # end
    # groups
  # end
  
  # Load metadatum values by group and key
  def get_metadatum_values_by_group_and_key(number, offset, sort, order, group, key)
    data = execute_query({
      :url => backend_url+'whitelab/search/metadata/'+group+'/'+key+'/values',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order,
        "count" => false
      },
      :headers => headers
    })
    data['values']
  end
  
  # Load metadatum values by label
  def get_metadatum_values_by_label(number, offset, sort, order, label)
    data = execute_query({
      :url => backend_url+'whitelab/search/metadata/'+label+'/values',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => headers
    })
    data['values']
  end
  
  def get_pos_tags(number, offset, sort, order)
    execute_query({
      :url => backend_url+'whitelab/search/pos/tags',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => headers
    })
  end
  
  def get_pos_heads_counted(number, offset, sort, order)
    execute_query({
      :url => backend_url+'whitelab/search/pos/heads',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => headers
    })
  end
  
  def get_pos_tag_by_label(label)
    execute_query({
      :url => backend_url+'whitelab/search/pos/tags/'+label,
      :headers => headers
    })
  end
  
  def get_pos_head_by_label(label)
    execute_query({
      :url => backend_url+'whitelab/search/pos/heads/'+label,
      :headers => headers
    })
  end
  
  def get_pos_tag_features_by_label(label)
    execute_query({
      :url => backend_url+'whitelab/search/pos/tags/'+label+'/features',
      :headers => headers
    })
  end
  
  def get_pos_head_features_by_label(label)
    execute_query({
      :url => backend_url+'whitelab/search/pos/heads/'+label+'/features',
      :headers => headers
    })
  end
  
  def get_pos_tag_types_by_label(number, offset, sort, order, label)
    resp = execute_query({
      :url => backend_url+'whitelab/search/pos/tags/'+label+'/word_types',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => headers
    })
    resp['word_types']
  end
  
  def get_pos_head_tags_by_label(number, offset, sort, order, label)
    execute_query({
      :url => backend_url+'whitelab/search/pos/heads/'+label+'/tags',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => headers
    })
  end
  
  def get_query_headers
    return headers
  end
  
  def get_results(path, search_obj)
    query = search_obj[:query]
    execute_query({
      :url => backend_url+'whitelab/search/'+path,
      :query => {  
        "pattern" => query.patt, 
        "filter" => query.filter, 
        "within" => search_obj[:within], 
        "number" => search_obj[:number], 
        "offset" => search_obj[:offset],
        "docpid" => search_obj[:docpid]
      },
      :headers => headers
    })
  end
  
  def get_search_results_for_query(query, docpid, offset, number)
    search_obj = {
      :query => query,
      :view => get_view(query, docpid, nil),
      :offset => get_offset(query, docpid, offset),
      :number => get_number(query, docpid, number),
      :within => get_within(query, 'document'),
      :docpid => docpid
    }
    view = search_obj[:view]
    if [1,2].include?(view)
      hits = view == 1
      key = hits ? "hits" : "docs"
      return { "results" => get_results(key, search_obj)[key] }
    elsif [8,16].include?(view)
      hit_groups = view == 8
      key = hit_groups ? "grouped_hits" : "grouped_docs"
      return { "results" => get_grouped_results(key, search_obj)[key] }
    end
  end
  
  def get_url
    return backend_url
  end
  
  # Turn filter string into a hash of positive and negative values
  def reformat_filters(filter)
    filter = filter[1, filter.length - 2]
    filters = {}
    filter.split(')AND(').each do |filter_part|
      parts = filter_part.split(/\!*=/)
      first_part = parts[0]
      second_part = parts[1]
      group = first_part.split('_')[0]
      key = first_part.sub(group+'_','')
      has_group = filters.has_key?(group)
      matches = has_group && filters[group].has_key?(key) ? filters[group][key] : { 'positive' => [], 'negative' => []}
      value = strip_value(second_part)
      if filter_part.eql?(first_part+'!='+second_part)
        matches['negative'] << value
      else
        matches['positive'] << value
      end
      filters[group] = {} unless has_group
      filters[group][key] = matches
    end
    filters
  end
  
  # Run CQL query on server for set amount of iterations
  def run_benchmark_test(cql,iterations)
    resp = execute_query({
      :url => backend_url+'whitelab/admin/test/query',
      :query => { 
        "query" => cql, 
        "iter" => iterations
      },
      :headers => headers,
      :method => 'post'
    })
  end
  
  # Update metadatum in index
  def update_metadatum(label, updates)
    updates.each do |key, value|
      execute_query({
        :url => backend_url+'whitelab/search/metadata/'+label+'/update',
        :query => {
          "property" => key,
          "value" => value.to_s
        },
        :headers => headers,
        :method => 'post'
      })
    end
  end
  
end