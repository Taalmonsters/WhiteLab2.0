# Neo4J backend helper methods.
module Neo4jHelper
  @@BACKEND_URL = Rails.configuration.x.database_url
  @@HEADERS = { 'Content-Type' => 'application/json',
                'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) }
  
  include BackendHelper
  include DataFormatHelper
  
  def count_docs(query, docpid, w, n, o)
    get_results("docs/count", query, docpid, w, n, o)
  end
  
  def count_grouped_docs(query, docpid, w, n, o)
    get_grouped_results("grouped_docs/count", query, docpid, w, n, o)
  end
  
  def count_grouped_hits(query, docpid, w, n, o)
    get_grouped_results("grouped_hits/count", query, docpid, w, n, o)
  end
  
  def count_hits(query, docpid, w, n, o)
    get_results("hits/count", query, docpid, w, n, o)
  end
  
  def db_type
    'neo4j'
  end
  
  # Load list of collection titles in index
  def get_collection_titles
    collections = []
    resp = execute_query({
      :url => @@BACKEND_URL+'db/data/label/Collection/nodes',
      :headers => @@HEADERS
    })
    resp.each do |node|
      label_resp = execute_query({
        :url => node['properties']+'/title',
        :headers => @@HEADERS
      })
      collections << label_resp
    end
    collections
  end
  
  # Load list of corpus titles in index
  def get_corpus_titles
    corpora = []
    resp = execute_query({
      :url => @@BACKEND_URL+'db/data/label/Corpus/nodes',
      :headers => @@HEADERS
    })
    resp.each do |node|
      label_resp = execute_query({
        :url => node['properties']+'/label',
        :headers => @@HEADERS
      })
      corpora << label_resp
    end
    corpora
  end
  
  # Get node containing total counts for all node labels in index
  def get_counter_node
    resp = execute_query({
      :url => @@BACKEND_URL+'db/data/label/NodeCounter/nodes',
      :headers => @@HEADERS
    })
    properties = execute_query({
      :url => resp[0]["properties"],
      :headers => @@HEADERS
    })
    return properties.except('status').sort
  end
  
  def get_docs(query, docpid, w, n, o)
    data = get_results("docs", query, docpid, w, n, o)
    data["docs"]
  end
  
  def get_docs_in_group(query,group,offset,number)
    filter = query.filter
    if filter.blank?
      filter = "("+query.group+"=\""+group+"\")"
    else
      filter = filter+"AND("+query.group+"=\""+group+"\")"
    end
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/docs',
      :query => { 
        "pattern" => pattern, 
        "filter" => filter, 
        "within" => query.within, 
        "number" => number, 
        "offset" => offset
      },
      :headers => @@HEADERS
    })
  end
  
  def get_document_content(xmlid, patt, offset, number)
    data = execute_query({
      :url => @@BACKEND_URL+'whitelab/search/docs/'+xmlid+'/content',
      :query => { 
        "offset" => offset,
        "number" => number,
        "pattern" => patt
      },
      :headers => @@HEADERS
    })
    # return data
    return data['content'][0]
  end
  
  def get_document_list
    data = `curl --header "Authorization: Basic bmVvNGo6Nzc0M21vbnN0ZXJzODE=" -H accept:application/json -H content-type:application/json -d '{"statements": [{ "statement": "MATCH (d:Document)<-[:HAS_DOCUMENT]->(cc:Collection) MATCH (cc)<-[:HAS_COLLECTION]-(c:Corpus) RETURN DISTINCT d.xmlid AS xmlid, d.token_count AS token_count, c.title AS corpus, cc.title AS collection;" }]}' http://localhost:7474/db/data/transaction/commit`;
    data = JSON.parse(data)
    docs = {}
    data["results"][0]["data"].each do |x|
      docs[x["row"][0]] = {"token_count" => x["row"][1], "corpus" => x["row"][2], "collection" => x["row"][3]}
    end
    docs
  end
  
  def get_document_metadata(xmlid)
    data = execute_query({
      :url => @@BACKEND_URL+'whitelab/search/docs/'+xmlid+'/metadata',
      :headers => @@HEADERS
    })
    data['metadata']
  end
  
  def get_document_statistics(xmlid)
    data = execute_query({
      :url => @@BACKEND_URL+'whitelab/search/docs/'+xmlid+'/statistics',
      :headers => @@HEADERS
    })
    data['statistics']
  end
  
  def get_filtered_content(query)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/metadata/content',
      :query => { 
        "filter" => query.filter,
        "pattern" => query.patt,
        "offset" => query.offset,
        "number" => query.number
      },
      :headers => @@HEADERS
    })
  end
  
  def get_grouped_docs(query, docpid, w, n, o)
    data = get_grouped_results("grouped_docs", query, docpid, w, n, o)
    data["grouped_docs"]
  end
  
  def get_grouped_hits(query, docpid, w, n, o)
    data = get_grouped_results("grouped_hits", query, docpid, w, n, o)
    data["grouped_hits"]
  end
  
  def get_grouped_results(path, query, docpid, w, n, o)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/'+path,
      :query => {  
        "pattern" => query.patt, 
        "filter" => query.filter, 
        "within" => w, 
        "number" => n, 
        "offset" => o,
        "docpid" => docpid,
        "group" => query.group
      },
      :headers => @@HEADERS
    })
  end
  
  def get_hits(query, docpid, w, n, o)
    data = get_results("hits", query, docpid, w, n, o)
    data["hits"]
  end
  
  def get_hits_in_group(query,group,offset,number)
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
    
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/hits',
      :query => { 
        "pattern" => pattern, 
        "filter" => filter, 
        "within" => query.within, 
        "number" => number, 
        "offset" => offset
      },
      :headers => @@HEADERS
    })
  end
  
  def get_kwic(docpid, first_index, last_index, size)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/hits/kwic',
      :query => { 
        "docpid" => docpid,
        "first_index" => first_index,
        "last_index" => last_index,
        "size" => size
      },
      :headers => @@HEADERS
    })
  end
  
  def get_metadata_from_server(number, offset, sort, order)
    get_metadata(number, offset, sort, order)
  end
  
  # Load paginated list of metadata in index
  def get_metadata(number, offset, sort, order)
    if number == 0
      execute_query({
        :url => @@BACKEND_URL+'db/data/label/Metadatum/nodes',
        :headers => @@HEADERS
      })
    else
      execute_query({
        :url => @@BACKEND_URL+'whitelab/search/metadata',
        :query => {"number" => number,
                   "offset" => offset,
                   "sort" => sort, 
                   "order" => order },
        :headers => @@HEADERS
      })
    end
  end
  
  # Load metadatum properties by label
  def get_metadatum_by_label(label)
    data = execute_query({
      :url => @@BACKEND_URL+'whitelab/search/metadata/'+label,
      :headers => @@HEADERS
    })
    data[0]
  end
  
  # # Load options for grouping by metadatum
  # def get_metadata_group_options(groups)
    # metadata_nodes = execute_query({
      # :url => @@BACKEND_URL+'db/data/label/Metadatum/nodes',
      # :headers => @@HEADERS
    # })
#     
    # metadata_nodes.each do |node|
      # node_properties = execute_query({
        # :url => node["properties"],
        # :headers => @@HEADERS
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
      :url => @@BACKEND_URL+'whitelab/search/metadata/'+group+'/'+key+'/values',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order,
        "count" => false
      },
      :headers => @@HEADERS
    })
    data['values']
  end
  
  # Load metadatum values by label
  def get_metadatum_values_by_label(number, offset, sort, order, label)
    data = execute_query({
      :url => @@BACKEND_URL+'whitelab/search/metadata/'+label+'/values',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => @@HEADERS
    })
    data['values']
  end
  
  def get_pos_tags(number, offset, sort, order)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/pos/tags',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => @@HEADERS
    })
  end
  
  def get_pos_heads_counted(number, offset, sort, order)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/pos/heads',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => @@HEADERS
    })
  end
  
  def get_pos_tag_by_label(label)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/pos/tags/'+label,
      :headers => @@HEADERS
    })
  end
  
  def get_pos_head_by_label(label)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/pos/heads/'+label,
      :headers => @@HEADERS
    })
  end
  
  def get_pos_tag_features_by_label(label)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/pos/tags/'+label+'/features',
      :headers => @@HEADERS
    })
  end
  
  def get_pos_head_features_by_label(label)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/pos/heads/'+label+'/features',
      :headers => @@HEADERS
    })
  end
  
  def get_pos_tag_types_by_label(number, offset, sort, order, label)
    resp = execute_query({
      :url => @@BACKEND_URL+'whitelab/search/pos/tags/'+label+'/word_types',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => @@HEADERS
    })
    resp['word_types']
  end
  
  def get_pos_head_tags_by_label(number, offset, sort, order, label)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/pos/heads/'+label+'/tags',
      :query => { 
        "number" => number,
        "offset" => offset,
        "sort" => sort,
        "order" => order
      },
      :headers => @@HEADERS
    })
  end
  
  def get_query_headers
    return @@HEADERS
  end
  
  def get_results(path, query, docpid, w, n, o)
    execute_query({
      :url => @@BACKEND_URL+'whitelab/search/'+path,
      :query => {  
        "pattern" => query.patt, 
        "filter" => query.filter, 
        "within" => w, 
        "number" => n, 
        "offset" => o,
        "docpid" => docpid
      },
      :headers => @@HEADERS
    })
  end
  
  def get_search_result_counts_for_query(query, docpid, view, number, offset)
    v = get_view(query, docpid, view)
    o = get_offset(query, docpid, offset)
    n = get_number(query, docpid, number)
    w = get_within(query, 'document')
    
    if v == 1
      count_hits(query, docpid, w, n, o)
    elsif v == 2
      count_docs(query, docpid, w, n, o)
    elsif v == 8
      count_grouped_hits(query, docpid, w, n, o)
    elsif v == 16
      count_grouped_docs(query, docpid, w, n, o)
    else
      logger.error "view = "+v.to_s
    end
  end
  
  def get_search_results_for_query(query, docpid, offset, number)
    v = get_view(query, docpid, nil)
    o = get_offset(query, docpid, offset)
    n = get_number(query, docpid, number)
    w = get_within(query, 'document')
    
    data = nil
    
    if v == 1
      data = get_hits(query, docpid, w, n, o)
    elsif v == 2
      data = get_docs(query, docpid, w, n, o)
    elsif v == 4
      data = get_filtered_content(query)
    elsif v == 8
      data = get_grouped_hits(query, docpid, w, n, o)
    elsif v == 16
      data = get_grouped_docs(query, docpid, w, n, o)
    end
    
    { "results" => data }
  end
  
  def get_url
    return @@BACKEND_URL
  end
  
  # Run CQL query on server for set amount of iterations
  def run_benchmark_test(cql,iterations)
    url = @@BACKEND_URL+'whitelab/admin/test/query'
    resp = execute_query({
      :url => @@BACKEND_URL+'whitelab/admin/test/query',
      :query => { 
        "query" => cql, 
        "iter" => iterations
      },
      :headers => @@HEADERS,
      :method => 'post'
    })
  end
  
  # Update metadatum in index
  def update_metadatum(label, updates)
    updates.each do |key, value|
      execute_query({
        :url => @@BACKEND_URL+'whitelab/search/metadata/'+label+'/update',
        :query => {
          "property" => key,
          "value" => value.to_s
        },
        :headers => @@HEADERS,
        :method => 'post'
      })
    end
  end
  
  def save_metadata
    File.open(Rails.root.join('config','metadata_neo4j.yml'), 'w', external_encoding: 'ASCII-8BIT') { |f| YAML.dump({ "metadata" => DOCUMENT_METADATA }, f) }
  end
  
end