# BlackLab backend helper methods.
module BlacklabHelper
  
  include BackendHelper
  include DataFormatHelper
  
  def count_grouped_results(key, count_obj)
    data = get_grouped_results(key, count_obj)["summary"]
    if !data["stillCounting"]
      return {
        "hit_count" => data["numberOfHits"],
        "document_count" => data["numberOfDocs"],
        "group_count" => data["numberOfGroups"]
      }
    else
      count_grouped_results(key, count_obj)
    end
  end
  
  def count_results(key, count_obj)
    data = get_results(key, count_obj)["summary"]
    if !data["stillCounting"]
      return {
        "hit_count" => data["numberOfHits"],
        "document_count" => data["numberOfDocs"]
      }
    else
      count_results(key, count_obj)
    end
  end
  
  def db_type
    'blacklab'
  end
  
  # Load list of collection titles in index
  def get_collection_titles
    get_titles('Collection')
  end
  
  # Load list of corpus titles in index
  def get_corpus_titles
    get_titles('Corpus')
  end
  
  def get_titles(key)
    resp = execute_query({
      :url => backend_url+"fields/#{key}_title",
      :query => {
        "outputformat" => "json"
      },
      :headers => { 'Content-Type' => 'application/json' }
    })
    resp["fieldValues"].keys
  end
  
  # Get node containing total counts for all node labels in index, not implemented for BlackLab
  def get_counter_node
  end
  
  def get_docs_in_group(query,group,offset,number)
    qgroup = query.group
    filter = query.filter
    filter = filter.blank? ? "("+qgroup+"=\""+group+"\")" : filter+"AND("+qgroup+"=\""+group+"\")"
    within = query.within
    execute_query({
      :url => backend_url+'docs',
      :query => { 
        "outputformat" => "json",
        "patt" => reformat_pattern(query.patt, within), 
        "filter" => reformat_filters(filter), 
        "within" => within, 
        "number" => number, 
        "first" => offset
      },
      :headers => headers
    })
  end
  
  def get_document_audio_file(xmlid)
    data = get_document_metadata(xmlid)["Metadata"]
    if data.has_key?("AudioExportFormat")
      format = data["AudioExportFormat"]
      format = format.kind_of?(Array) ? format[0] : format
      return "#{format}/#{xmlid}.#{format}"
    end
    "Unknown"
  end
  
  def get_document_content(xmlid, patt, offset, number)
    data = {
      "audio_file" => get_document_audio_file(xmlid),
      "total_sentence_count" => get_document_sentence_count(xmlid)
    }
    sdata = []
    sentences = get_document_sentence_starts(xmlid, offset, number+1)["hits"]
    sentence_count = sentences.length
    (offset..offset+number-1).each_with_index do |sentence_number, index|
      next_index = index + 1
      if sentence_count > next_index
        snippet_length = sentences[next_index]["start"]
      else
        snippet_length = get_document_token_count(xmlid)
      end
      if sentence_count > index
        sentence = get_document_snippet(xmlid, sentences[index]["start"], snippet_length)
        sdata << sentence["match"]
      end
    end
    
    data["content"] = reformat_content(xmlid, sdata)
    return data
  end
  
  def get_document_list
    docs = {}
    get_corpus_titles.each do |corpus|
      docs.merge!(get_corpus_document_list(corpus))
    end
    docs
  end
  
  def get_corpus_document_list(corpus)
    docs = {}
    offset = 0
    number = 500
    while true do
      resp = execute_query({
        :url => backend_url+'docs',
        :query => {
          "filter" => "Corpus_title:"+corpus,
          "first" => offset,
          "number" => number,
          "outputformat" => "json"
        },
        :headers => { 'Content-Type' => 'application/json' }
      })
      resp["docs"].each do |doc|
        doc_info = doc["docInfo"]
        docs[doc["docPid"]] = {"token_count" => doc_info["lengthInTokens"], "corpus" => corpus, "collection" => doc_info["Collection_title"]}
      end
      break unless resp["summary"]["windowHasNext"]
      offset = offset + number
    end
    docs
  end
  
  def get_document_metadata(xmlid)
    data = execute_query({
      :url => backend_url+'docs/'+xmlid,
      :query => {
        "outputformat" => "json"
      },
      :headers => headers
    })
    metadata = {
      "Metadata" => {}
    }
    data['docInfo'].each do |key, value|
      metadata["Metadata"][key] = [value]
    end
    metadata
  end
  
  def get_document_sentence_count(xmlid)
    data = execute_query({
      :url => backend_url+'hits',
      :query => {
        "outputformat" => "json",
        "patt" => '[xmlid="(p.[0-9]+.)*(s.)*[0-9]+.(w.)*1"]',
        "filter" => "id:"+xmlid,
        "first" => 0,
        "number" => 1
      },
      :headers => headers
    })["summary"]
    if data["stillCounting"].to_s.eql?('true')
      get_document_sentence_count(xmlid)
    else
      return data["numberOfHits"]
    end
  end
  
  def get_document_sentence_starts(xmlid, offset, number)
    execute_query({
      :url => backend_url+'hits',
      :query => {
        "outputformat" => "json",
        "patt" => '[xmlid="(p.[0-9]+.)*(s.)*[0-9]+.(w.)*1"]',
        "filter" => "id:"+xmlid,
        "first" => offset,
        "number" => number
      },
      :headers => headers
    })
  end
  
  def get_document_snippet(xmlid, hitstart, hitend)
    execute_query({
      :url => backend_url+'docs/'+xmlid+'/snippet',
      :query => {
        "outputformat" => "json",
        "hitstart" => hitstart,
        "hitend" => hitend,
        "wordsaroundhit" => 0
      },
      :headers => headers
    })
  end
  
  def get_document_statistics(xmlid)
    token_count = get_document_token_count(xmlid)
    contents = get_document_snippet(xmlid, 0, token_count)["match"]
    type_count = contents["word"].uniq.count
    lemma_count = contents["lemma"].uniq.count
    
    return {
      "token_count" => token_count,
      "type_count" => type_count,
      "lemma_count" => lemma_count
    }
  end
  
  def get_filtered_content(query)
    contents = []
    get_filtered_documents(query.filter).each do |doc|
      contents = contents + get_document_content(doc, query.patt, 0, get_document_sentence_count(doc))
    end
    contents
  end
  
  def get_grouped_results(path, search_obj)
    query = search_obj[:query]
    execute_query({
      :url => backend_url+path,
      :query => {  
        "outputformat" => "json",
        "patt" => reformat_pattern(query.patt, search_obj[:within]), 
        "filter" => reformat_filters(query.filter),
        "number" => search_obj[:number], 
        "first" => search_obj[:offset],
        "group" => reformat_group(query.group)
      },
      :headers => headers
    })
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
    elsif filter.blank?
      filter = "("+qgroup+"=\""+group+"\")"
    else
      filter = filter+"AND("+qgroup+"=\""+group+"\")"
    end
    
    execute_query({
      :url => backend_url+'hits',
      :query => { 
        "outputformat" => "json",
        "patt" => pattern, 
        "filter" => reformat_filters(filter), 
        "within" => query.within, 
        "number" => number, 
        "first" => offset
      },
      :headers => headers
    })
  end
  
  def get_kwic(docpid, first_index, last_index, size = 50)
    data = execute_query({
      :url => backend_url+'docs/'+docpid+'/snippet',
      :query => {
        "outputformat" => "json",
        "hitstart" => first_index,
        "hitend" => last_index+1,
        "wordsaroundhit" => size
      },
      :headers => headers
    })
    kwic = {
      "left_context" => data["left"]["word"].join(" "),
      "hit_text" => data["match"]["word"].join(" "),
      "right_context" => data["right"]["word"].join(" ")
    }
  end
  
  def get_metadata_from_server(number, offset, sort, order)
    resp = execute_query({
      :url => backend_url,
      :query => {
        "outputformat" => "json"
      },
      :headers => { 'Content-Type' => 'application/json' }
    })
    fields = resp["fieldInfo"]["metadataFields"]
    wanted = number == 0 ? fields : fields.keys[offset..offset+number]
    data = []
    fields.each do |key, value|
      data << value if wanted.include?(key)
    end
    return data
  end
  
  def get_pos_heads_counted(number, offset, sort, order)
    data = ['ADJ', 'BW', 'LET', 'LID', 'N', 'SPEC', 'TW', 'TSW', 'VG', 'VNW', 'VZ', 'WW']
    ph = {
      "total" => data.size,
      "number" => number,
      "offset" => offset,
      "sort" => sort,
      "order" => order,
      "pos_heads" => []
    }
    data[offset..offset+number-1].each do |head|
      ph["pos_heads"] << get_pos_head_counts(head)
    end
    ph
  end
  
  def get_pos_head_counts(head)
    obj = {
      "label" => head,
      "token_count" => 0
    }
    get_corpus_titles.each do |corpus|
      while true do
        resp = execute_query({
          :url => backend_url+"/hits",
          :query => {  
            "outputformat" => "json",
            "patt" => "[pos=\"#{head}.*\"]", 
            "group" => "hit:pos",
            "filter" => "Corpus_title:"+corpus
          },
          :headers => headers
        })["summary"]
        break unless resp["stillCounting"]
      end
      hit_count = resp["numberOfHits"]
      obj["token_count"] += hit_count
      obj["token_count_"+corpus] = hit_count
    end
    obj
  end
  
  def get_pos_tag_by_label(label)
    reformat_pos_tag({ "label" => label })
  end
  
  def get_pos_tag_features_by_label(label)
    feats = []
    label.split(/\(/)[1].sub(/\)^/,"").split(/,/).each do |feat|
      feats << { "key" => "unknown", "value" => feat }
    end
    feats
  end
  
  def get_pos_tag_types_by_label(number, offset, sort, order, label)
    pid = label.gsub(/\(/,'\(').gsub(/\)/,'\)').gsub(/\-/,'\-')
    patt = "[pos=\"#{pid}\"]"
    resp = execute_query({
      :url => backend_url+"/hits",
      :query => {  
        "outputformat" => "json",
        "patt" => patt, 
        "group" => "hit:word",
        "number" => number,
        "first" => offset,
        "sort" => "size"
      },
      :headers => headers
    })
    data = []
    resp["hitGroups"].each do |hit|
      data << { "word_type" => hit["identityDisplay"], "token_count" => hit["size"]}
    end
    data
  end
  
  def get_pos_tags(number, offset, sort, order)
    while true do
      resp = execute_query({
        :url => backend_url+"/hits",
        :query => {  
          "outputformat" => "json",
          "patt" => "[\"..*\"]", 
          "group" => "hit:pos",
          "number" => number,
          "first" => offset,
          "sort" => order.eql?("desc") ? "-identity" : "identity"
        },
        :headers => headers
      })
      summary = resp["summary"]
      break unless summary["stillCounting"]
    end
    { 'total' => summary["numberOfGroups"], 'pos_tags' => resp["hitGroups"].map{|hit_group| reformat_pos_tag(hit_group) } }
  end
  
  def get_query_headers
    return headers
  end
  
  def get_results(path, search_obj)
    query = search_obj[:query]
    execute_query({
      :url => backend_url+path,
      :query => {  
        "outputformat" => "json",
        "patt" => reformat_pattern(query.patt, search_obj[:within]), 
        "filter" => reformat_filters(query.filter),
        "number" => search_obj[:number], 
        "first" => search_obj[:offset]
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
      output = {
        :query => query,
        :data => get_results(key, search_obj)[key]
      }
      return { "results" => hits ? reformat_hits_output(output) : reformat_docs_output(output) }
    elsif [8,16].include?(view)
      hit_groups = view == 8
      search_key = hit_groups ? "hits" : "docs"
      result_key = hit_groups ? "hitGroups" : "docGroups"
      output = {
        :query => query,
        :data => get_grouped_results(search_key, search_obj)[result_key]
      }
      return { "results" => reformat_grouped_output(output, hit_groups ? 'hit_count' : 'document_count') }
    end
  end
  
  def get_url
    return backend_url
  end
  
  # Reformat BlackLab content output to same format as Neo4J
  def reformat_content(xmlid, data)
    token_index = 0
    reformat = []
    data.each do |sentence|
      arr, token_index = reformat_sentence_content(xmlid, sentence, token_index)
      reformat.push(*arr)
    end
    reformat
  end
  
  def reformat_sentence_content(xmlid, sentence, token_index)
    reformat = []
    sentence["word"].each_with_index do |word, index|
      token_index += 1
      obj = {
        :token_index => token_index,
        :xmlid => xmlid,
        :sentence => sentence,
        :word => word,
        :index => index
      }
      reformat << reformat_word_content(obj)
    end
    return reformat, token_index
  end
  
  def reformat_word_content(obj)
    token = { "word_type" => obj[:word], "token_index" => obj[:token_index] }
    ["lemma", "pos", "phonetic", "xmlid", "speaker", "begin_time", "end_time"].each do |field|
      token = reformat_field_content(obj, field, token)
    end
    token
  end
  
  def reformat_field_content(obj, field, token)
    sentence_field = obj[:sentence][field][obj[:index]]
    if field.eql?("pos")
      token[field+"_tag"] = sentence_field
    elsif field.eql?("speaker")
      token["sentence_"+field] = sentence_field
    elsif field.eql?("xmlid")
      token[field] = obj[:xmlid]+"."+sentence_field
      if sentence_field =~ /\.(s\.)*1\.(w\.)*1$/
        token["paragraph_start"] = "true"
      else
        token["paragraph_start"] = "false"
      end
      if sentence_field =~ /\.(w\.)*1$/
        token["sentence_start"] = "true"
      else
        token["sentence_start"] = "false"
      end
    elsif sentence.has_key?(field)
      token[field] = sentence_field
    end
    token
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
  
  def reformat_hits_output(output)
    reformat = []
    docs = {}
    output[:data].each do |hit|
      doc_pid = hit["docPid"]
      if !docs.has_key?(doc_pid)
        metadata = get_document_metadata(doc_pid)["Metadata"]
        docs[doc_pid] = {
          "corpus" => metadata["Corpus_title"],
          "collection" => metadata["Collection_title"]
        }
      end
      doc = docs[doc_pid]
      match = hit["match"]
      reformat << {
        "text_left" => hit["left"]["word"].join(" "),
        "corpus" => doc["corpus"],
        "collection" => doc["collection"],
        "hit_text"=> match["word"].join(" "),
        "last_index" => hit["end"]-1,
        "text_right" => hit["right"]["word"].join(" "),
        "docpid" => doc_pid,
        "end_time" => "Unknown",
        "begin_time" => "Unknown",
        "hit_pos" => match["pos"].join(" "),
        "hit_phonetic" => reformat_phonetic(match["phonetic"]),
        "first_index" => hit["start"],
        "hit_lemma" => match["lemma"].join(" ")
      }
    end
    reformat
  end
  
  def reformat_docs_output(output)
    reformat = []
    output[:data].each do |doc|
      doc_info = doc["docInfo"]
      reformat << {
        "corpus" => doc_info["Corpus_title"],
        "docpid" => doc["docPid"],
        "collection" => doc_info["Collection_title"],
        "hit_count" => doc["numberOfHits"]
      }
    end
    reformat
  end
  
  def reformat_grouped_output(output, count_key)
    reformat = []
    output[:data].each do |group|
      reformat << {
        "#{query.group}" => group["identityDisplay"],
        "#{count_key}" => group["size"]
      }
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
  
  def reformat_pos_tag(pos)
    obj = { "label" => pos.has_key?("label") ? pos["label"] : pos["identityDisplay"], "token_count" => 0 }
    get_corpus_titles.each do |corpus|
      pid = obj["label"].gsub(/\(/,'\(').gsub(/\)/,'\)').gsub(/\-/,'\-')
      patt = "[pos=\"#{pid}\"]"
      while true do
        resp = execute_query({
          :url => backend_url+"/hits",
          :query => {  
            "outputformat" => "json",
            "patt" => patt,
            "filter" => "Corpus_title:#{corpus}"
          },
          :headers => headers
        })["summary"]
        break unless resp["stillCounting"]
      end
      hits = resp["numberOfHits"]
      obj["token_count"] += hits
      obj["token_count_#{corpus}"] = hits
    end
    obj
  end
  
  # Run CQL query on server for set amount of iterations, not implemented for BlackLab
  def run_benchmark_test(cql,iterations)
  end
  
end