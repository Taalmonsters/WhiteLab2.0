# BlackLab backend helper methods.
module BlacklabHelper
  @@BACKEND_URL = Rails.configuration.x.database_url
  @@HEADERS = { 'Content-Type' => 'application/json' }
  
  include BackendHelper
  include DataFormatHelper
  
  def count_docs(query, w, n, o)
    data = get_results("docs", query, w, n, o)
    if !data["summary"]["stillCounting"]
      return {
        "hit_count" => data["summary"]["numberOfHits"],
        "document_count" => data["summary"]["numberOfDocs"]
      }
    else
      count_docs(query, w, n, o)
    end
  end
  
  def count_grouped_docs(query, w, n, o)
    data = get_grouped_results("docs", query, w, n, o)
    if !data["summary"]["stillCounting"]
      return {
        "hit_count" => data["summary"]["numberOfHits"],
        "document_count" => data["summary"]["numberOfDocs"],
        "group_count" => data["summary"]["numberOfGroups"]
      }
    else
      count_grouped_docs(query, w, n, o)
    end
  end
  
  def count_grouped_hits(query, w, n, o)
    data = get_grouped_results("hits", query, w, n, o)
    if !data["summary"]["stillCounting"]
      return {
        "hit_count" => data["summary"]["numberOfHits"],
        "document_count" => data["summary"]["numberOfDocs"],
        "group_count" => data["summary"]["numberOfGroups"]
      }
    else
      count_grouped_hits(query, w, n, o)
    end
  end
  
  def count_hits(query, w, n, o)
    data = get_results("hits", query, w, n, o)
    if !data["summary"]["stillCounting"]
      return {
        "hit_count" => data["summary"]["numberOfHits"],
        "document_count" => data["summary"]["numberOfDocs"]
      }
    else
      count_hits(query, w, n, o)
    end
  end
  
  # Load list of collection titles in index
  def get_collection_titles
    collections = []
    resp = execute_query({
      :url => @@BACKEND_URL+'fields/Collection_title',
      :query => {
        "outputformat" => "json"
      },
      :headers => { 'Content-Type' => 'application/json' }
    })
    resp["fieldValues"].each do |collection, doc_count|
      collections << collection
    end
    collections
  end
  
  # Load list of corpus titles in index
  def get_corpus_titles
    corpora = []
    resp = execute_query({
      :url => @@BACKEND_URL+'fields/Corpus_title',
      :query => {
        "outputformat" => "json"
      },
      :headers => { 'Content-Type' => 'application/json' }
    })
    resp["fieldValues"].each do |corpus, doc_count|
      corpora << corpus
    end
    corpora
  end
  
  # Get node containing total counts for all node labels in index, not implemented for BlackLab
  def get_counter_node
  end
  
  def get_docs(query, w, n, o)
    data = get_results("docs", query, w, n, o)
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
      :url => @@BACKEND_URL+'docs',
      :query => { 
        "outputformat" => "json",
        "patt" => pattern, 
        "filter" => reformat_filters(filter), 
        "within" => query.within, 
        "number" => number, 
        "first" => offset
      },
      :headers => @@HEADERS
    })
  end
  
  def get_document_audio_file(xmlid)
    data = get_document_metadata(xmlid)
    if data["Metadata"].has_key?("AudioExportFormat")
      if data["Metadata"]["AudioExportFormat"].respond_to?('each')
        return data["Metadata"]["AudioExportFormat"][0]+"/"+xmlid+"."+data["Metadata"]["AudioExportFormat"][0]
      else
        return data["Metadata"]["AudioExportFormat"]+"/"+xmlid+"."+data["Metadata"]["AudioExportFormat"]
      end
    end
    "Unknown"
  end
  
  def get_document_content(xmlid, patt, offset, number)
    data = {
      "audio_file" => get_document_audio_file(xmlid),
      "total_sentence_count" => get_document_sentence_count(xmlid)
    }
    sdata = []
    sentences = get_document_sentence_starts(xmlid, offset, number+1)
    ss = sentences["hits"].length
    (offset..offset+number-1).each_with_index do |s, i|
      if sentences["hits"].length > s+1
        t = sentences["hits"][i+1]["start"]
      else
        t = get_document_token_count(xmlid)
      end
      if sentences["hits"].length > i
        sentence = get_document_snippet(xmlid, sentences["hits"][i]["start"], t)
        sdata << sentence["match"]
      end
    end
    
    data["content"] = reformat_content(sdata)
    return data
  end
  
  def get_document_list
    docs = {}
    get_corpus_titles.each do |corpus|
      busy = true
      o = 0
      n = 500
      while busy do
        resp = execute_query({
          :url => @@BACKEND_URL+'docs',
          :query => {
            "filter" => "Corpus_title:"+corpus,
            "first" => o,
            "number" => n,
            "outputformat" => "json"
          },
          :headers => { 'Content-Type' => 'application/json' }
        })
        resp["docs"].each do |doc|
          docs[doc["docPid"]] = {"token_count" => doc["docInfo"]["lengthInTokens"], "corpus" => corpus, "collection" => doc["docInfo"]["Collection_title"]}
        end
        busy = resp["summary"]["windowHasNext"]
        o = o + n
      end
    end
    docs
  end
  
  def get_document_metadata(xmlid)
    data = execute_query({
      :url => @@BACKEND_URL+'docs/'+xmlid,
      :query => {
        "outputformat" => "json"
      },
      :headers => @@HEADERS
    })
    metadata = {
      "Metadata" => {}
    }
    data['docInfo'].each do |m, v|
      metadata["Metadata"][m] = [v]
    end
    metadata
  end
  
  def get_document_sentence_count(xmlid)
    data = execute_query({
      :url => @@BACKEND_URL+'hits',
      :query => {
        "outputformat" => "json",
        "patt" => '[sentence_start="true"]',
        "filter" => "id:"+xmlid,
        "first" => 0,
        "number" => 1
      },
      :headers => @@HEADERS
    })
    if data["summary"]["stillCounting"].to_s.eql?('true')
      get_document_sentence_count(xmlid)
    else
      return data["summary"]["numberOfHits"]
    end
  end
  
  def get_document_sentence_starts(xmlid, o, n)
    execute_query({
      :url => @@BACKEND_URL+'hits',
      :query => {
        "outputformat" => "json",
        "patt" => '[sentence_start="true"]',
        "filter" => "id:"+xmlid,
        "first" => o,
        "number" => n
      },
      :headers => @@HEADERS
    })
  end
  
  def get_document_snippet(xmlid, hitstart, hitend)
    execute_query({
      :url => @@BACKEND_URL+'docs/'+xmlid+'/snippet',
      :query => {
        "outputformat" => "json",
        "hitstart" => hitstart,
        "hitend" => hitend,
        "wordsaroundhit" => 0
      },
      :headers => @@HEADERS
    })
  end
  
  def get_document_statistics(xmlid)
    token_count = get_document_token_count(xmlid)
    contents = get_document_snippet(xmlid, 0, token_count)
    type_count = contents["match"]["word"].uniq.count
    lemma_count = contents["match"]["lemma"].uniq.count
    
    return {
      "token_count" => token_count,
      "type_count" => type_count,
      "lemma_count" => lemma_count
    }
  end
  
  def get_document_token_count(xmlid)
    data = get_document_metadata(xmlid)
    return data["Metadata"]["lengthInTokens"][0]
  end
  
  def get_filtered_content(query)
    contents = []
    get_filtered_documents(query.filter).each do |doc|
      contents = contents + get_document_content(doc, query.patt, 0, get_document_sentence_count(doc))
    end
    contents
  end
  
  def get_grouped_docs(query, w, n, o)
    data = get_grouped_results("docs", query, w, n, o)
    data["docGroups"]
  end
  
  def get_grouped_hits(query, w, n, o)
    data = get_grouped_results("hits", query, w, n, o)
    data["hitGroups"]
  end
  
  def get_grouped_results(path, query, w, n, o)
    execute_query({
      :url => @@BACKEND_URL+path,
      :query => {  
        "outputformat" => "json",
        "patt" => reformat_pattern(query.patt, w), 
        "filter" => reformat_filters(query.filter),
        "number" => n, 
        "first" => o,
        "group" => reformat_group(query.group)
      },
      :headers => @@HEADERS
    })
  end
  
  def get_hits(query, w, n, o)
    data = get_results("hits", query, w, n, o)
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
      :url => @@BACKEND_URL+'hits',
      :query => { 
        "outputformat" => "json",
        "patt" => pattern, 
        "filter" => reformat_filters(filter), 
        "within" => query.within, 
        "number" => number, 
        "first" => offset
      },
      :headers => @@HEADERS
    })
  end
  
  def get_kwic(docpid, first_index, last_index, size)
    data = execute_query({
      :url => @@BACKEND_URL+'docs/'+docpid+'/snippet',
      :query => {
        "outputformat" => "json",
        "hitstart" => first_index,
        "hitend" => last_index+1,
        "wordsaroundhit" => size
      },
      :headers => @@HEADERS
    })
    kwic = {
      "left_context" => data["left"]["word"].join(" "),
      "hit_text" => data["match"]["word"].join(" "),
      "right_context" => data["right"]["word"].join(" ")
    }
  end
  
  # Load paginated list of metadata in index
  def get_metadata(number, offset, sort, order)
    resp = execute_query({
      :url => @@BACKEND_URL,
      :query => {
        "outputformat" => "json"
      },
      :headers => { 'Content-Type' => 'application/json' }
    })
    fields = resp["fieldInfo"]["metadataFields"]
    if number == 0
      wanted = fields
    else
      wanted = fields.keys[offset..offset+number]
    end
    data = []
    fields.each do |key, value|
      if wanted.include?(key)
        data << value
      end
    end
    return data
  end
  
  # Load metadatum properties by label
  def get_metadatum_by_label(label)
    execute_query({
      :url => @@BACKEND_URL+'fields/'+label,
      :query => {
        "outputformat" => "json"
      },
      :headers => { 'Content-Type' => 'application/json' }
    })
  end
  
  # Load options for grouping by metadatum
  def get_metadata_group_options(groups)
    resp = execute_query({
      :url => @@BACKEND_URL,
      :query => {
        "outputformat" => "json"
      },
      :headers => { 'Content-Type' => 'application/json' }
    })
    fields = resp["fieldInfo"]["metadataFields"]
    groups['Metadata'] = []
    fields.each do |key,field|
      groups['Metadata'] << [field['displayName'], field['fieldName']]
    end
    groups
  end
  
  # Load metadatum values by group and key
  def get_metadatum_values_by_group_and_key(number, offset, sort, order, group, key, count)
    if group.eql?('Metadata')
      get_metadatum_values_by_label(number, offset, sort, order, key)
    else
      get_metadatum_values_by_label(number, offset, sort, order, group+'_'+key)
    end
  end
  
  # Load metadatum values by label
  def get_metadatum_values_by_label(number, offset, sort, order, label)
    resp = execute_query({
      :url => @@BACKEND_URL+'fields/'+label,
      :query => {
        "outputformat" => "json"
      },
      :headers => { 'Content-Type' => 'application/json' }
    })
    if number == 0
      return resp["fieldValues"]
    end
    resp["fieldValues"][offset..offset+number]
  end
  
  def get_pos_heads(number, offset, sort, order)
    orig_sort = sort
    if sort.eql?('label')
      sort = 'identity'
    else
      sort = 'size'
    end
    if order.eql?('desc')
      sort = '-'+sort
    end
    data = execute_query({
      :url => @@BACKEND_URL+'hits',
      :query => { 
        "outputformat" => "json",
        "patt" => '[poshead="..*"]',
        "group" => 'hit:poshead:s',
        "number" => number,
        "offset" => offset,
        "sort" => sort
      },
      :headers => @@HEADERS
    })
    ph = {
      "total" => data["summary"]["numberOfGroups"],
      "number" => number,
      "offset" => offset,
      "sort" => orig_sort,
      "order" => order,
      "pos_heads" => []
    }
    data["hitGroups"].each do |group|
      ph["pos_heads"] << {
        "label" => group["identityDisplay"],
        "token_count" => group["size"]
      }
    end
    ph
  end
  
  def get_query_headers
    return @@HEADERS
  end
  
  def get_results(path, query, w, n, o)
    execute_query({
      :url => @@BACKEND_URL+path,
      :query => {  
        "outputformat" => "json",
        "patt" => reformat_pattern(query.patt, w), 
        "filter" => reformat_filters(query.filter),
        "number" => n, 
        "first" => o
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
      count_hits(query, w, n, o)
    elsif v == 2
      count_docs(query, w, n, o)
    elsif v == 8
      count_grouped_hits(query, w, n, o)
    elsif v == 16
      count_grouped_docs(query, w, n, o)
    end
  end
  
  def get_search_results_for_query(query, docpid, offset, number)
    v = get_view(query, docpid, nil)
    o = get_offset(query, docpid, offset)
    n = get_number(query, docpid, number)
    w = get_within(query, 'document')
    
    data = nil
    
    if v == 1
      data = get_hits(query, w, n, o)
    elsif v == 2
      data = get_docs(query, w, n, o)
    elsif v == 4
      data = get_filtered_content(query)
    elsif v == 8
      data = get_grouped_hits(query, w, n, o)
    elsif v == 16
      data = get_grouped_docs(query, w, n, o)
    end
    
    { "results" => reformat_output(query, data, v) }
  end
  
  def get_url
    return @@BACKEND_URL
  end
  
  # Reformat BlackLab content output to same format as Neo4J
  def reformat_content(data)
    t = 0
    fields = ["lemma", "pos", "phonetic", "xmlid", "paragraph_start", "sentence_start", "sentence_speaker"]
    reformat = []
    data.each do |sentence|
      sentence["word"].each_with_index do |word, i|
        t = t+1
        token = { "word_type" => word, "token_index" => t }
        fields.each do |field|
          if field.eql?("pos")
            token[field+"_tag"] = sentence[field][i]
          else
            token[field] = sentence[field][i]
          end
        end
        reformat << token
      end
    end
    reformat
  end
  
  # Reformat filters to BlackLab format (filter:value)
  def reformat_filters(filters)
    if !filters.blank?
      return filters.gsub('=',':')
    end
    return ''
  end
  
  def reformat_group(group)
    if group.start_with?('hit_') || group.end_with?('_left') || group.end_with?('_right')
      group.gsub('_',':').gsub('left','leftword').gsub('right','rightword').gsub('hit:text','hit:word')
    else
      'field:'+group
    end
  end
  
  def reformat_output(query, data, view)
    reformat = []
    docs = {}
    if view == 1
      data.each do |hit|
        if !docs.has_key?(hit["docPid"])
          metadata = get_document_metadata(hit["docPid"])
          docs[hit["docPid"]] = {
            "corpus" => metadata["Metadata"]["Corpus_title"],
            "collection" => metadata["Metadata"]["Collection_title"]
          }
        end
        reformat << {
          "text_left" => hit["left"]["word"].join(" "),
          "corpus" => docs[hit["docPid"]]["corpus"],
          "collection" => docs[hit["docPid"]]["collection"],
          "hit_text"=> hit["match"]["word"].join(" "),
          "last_index" => hit["end"]-1,
          "text_right" => hit["right"]["word"].join(" "),
          "docpid" => hit["docPid"],
          "end_time" => "Unknown",
          "begin_time" => "Unknown",
          "hit_pos" => hit["match"]["pos"].join(" "),
          "hit_phonetic" => reformat_phonetic(hit["match"]["phonetic"]),
          "first_index" => hit["start"],
          "hit_lemma" => hit["match"]["lemma"].join(" ")
        }
      end
    elsif view == 2
      data.each do |doc|
        reformat << {
          "corpus" => doc["docInfo"]["Corpus_title"],
          "docpid" => doc["docPid"],
          "collection" => doc["docInfo"]["Collection_title"],
          "hit_count" => doc["numberOfHits"]
        }
      end
    elsif view == 4
      reformat = data
    elsif view == 8
      data.each do |hitgroup|
        reformat << {
          query.group => docgroup["identityDisplay"],
          "hit_count" => docgroup["size"]
        }
      end
    elsif view == 16
      data.each do |docgroup|
        reformat << {
          query.group => docgroup["identityDisplay"],
          "document_count" => docgroup["size"]
        }
      end
    end
    reformat
  end
  
  def reformat_pattern(patt, within)
    if within.eql?('paragraph')
      patt + ' within (<p/> | <event/>)'
    elsif within.eql?('sentence')
      patt + ' within <s/>'
    end
    patt
  end
  
  def reformat_phonetic(phonetic)
    has_phonetic = false
    
    phonetic.each do |ph|
      if ph.length > 0 
        has_phonetic = true
        break
      end
    end
    
    if has_phonetic
      phonetic.join(" ")
    else
      ""
    end
  end
  
  # Run CQL query on server for set amount of iterations, not implemented for BlackLab
  def run_benchmark_test(cql,iterations)
  end
  
  # Update metadatum in index, not implemented for BlackLab
  def update_metadatum(label, updates)
  end
  
end