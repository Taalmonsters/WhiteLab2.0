# Backend helper specifically for BlackLab Server (http://inl.github.io/BlackLab/).
module BlacklabHelper
  
  include BackendHelper
  include DataFormatHelper

  # If gap values are enabled, the 'Import TSV' buttons in Expert Search and Explore N-grams are active.
  # If gap values are disabled, the 'Import TSV' buttons show an alert explaining the functionality, but do not allow file upload.
  # The functionality will likely become available in BlackLab version 1.6.0.
  def gap_values_enabled
    return self.version.gsub('.','').gsub('-SNAPSHOT','').to_i > 150
  end

  # Get the base URL for a query based on the selected view
  def query_to_url(query)
    page = [1,8].include?(query.view) ? "hits" : "docs"
    return "#{backend_url}#{page}"
  end

  # Reformat the WhiteLab query parameters to match BlackLab parameters
  def reformat_query_attributes(query)
    attrs = { 'outputformat' => 'json' }
    query.as_json.select{|key,_| ['patt', 'filter', 'group', 'sort', 'offset', 'number', 'docpid', 'viewgroup', 'sample', 'samplenum', 'sampleseed', 'gap_values_tsv'].include?(key) }.each do |key, value|
      unless value.blank?
        if ['filter', 'group'].include?(key)
          attrs[key] = reformat_filters(value) if key.eql?('filter')
          attrs[key] = reformat_group(value) if key.eql?('group') && ([8,16].include?(query.view) || !query.viewgroup.blank?)
        elsif key.eql?('gap_values_tsv')
          attrs['pattgapdata'] = value
        else
          key = 'first' if key.eql?('offset')
          value = combine_patt_and_within(query) if key.eql?('patt')
          attrs[key] = value
        end
      end
    end
    attrs["sort"] = "size" unless !attrs.has_key?("group") || attrs.has_key?("sort") || (attrs.has_key?("viewgroup") && query.view == 2)
    return attrs
  end

  # Combine the value of the within parameter with the query pattern
  def combine_patt_and_within(query)
    within = query.within
    patt = query.patt
    return patt if within.blank? || within.eql?('document')
    return "#{patt} within (<p/> | <event/>)" if within.eql?('paragraph')
    return "#{patt} within <s/>" if within.eql?('sentence')
  end

  # Finish query execution
  def finish_query(query, response)
    Rails.logger.debug "FINISHING QUERY"
    Rails.logger.debug query
    view = query.view
    grouped = [8,16].include?(view)
    hits = [1,8].include?(view)
    key = hits ? "hit" : "doc"
    key = grouped ? "#{key}Groups" : "#{key}s"
    Rails.logger.debug "KEY: #{key}"
    status = response.has_key?(key) ? response['summary']['stillCounting'] ? 2 : 3 : 4
    output = reformat_output(response, key, query)
    Rails.logger.debug "QUERY STATUS = #{status}"
    return output, status
  end

  # Reformat BlackLab Server output to match the format expected by WhiteLab
  def reformat_output(response, key, query)
    view = query.view
    return {
      'error' => "#{response['error']['code']}: #{response['error']['message']}"
    } unless response.has_key?(key)
    summary = response['summary']
    hits = summary['numberOfHits']
    docs = summary['numberOfDocs']
    data = response[key]
    return {
      'hit_count' => hits,
      'document_count' => docs,
      'documents' => response['docInfos'],
      'sampleseed' => response['summary'].has_key?('sampleSeed') ? response['summary']['sampleSeed'] : nil,
      'results' => data.map { |hit|
        {
          "corpus" => response['docInfos'][hit["docPid"]][CORPUS_TITLE_FIELD],
          "collection" => response['docInfos'][hit["docPid"]][COLLECTION_TITLE_FIELD],
          "docpid" => hit["docPid"],
          "text_left" => hit["left"]["word"].join(" "),
          "hit_text"=> hit["match"]["word"].join(" "),
          "text_right" => hit["right"]["word"].join(" "),
          "hit_pos" => hit["match"].has_key?("pos") ? hit["match"]["pos"].join(" ") : nil,
          "hit_phonetic" => hit["match"].has_key?("phonetic") ? reformat_phonetic(hit["match"]["phonetic"]) : nil,
          "hit_lemma" => hit["match"].has_key?("lemma") ? hit["match"]["lemma"].join(" ") : nil,
          "first_index" => hit["start"],
          "last_index" => hit["end"]-1,
          "end_time" => hit["match"].has_key?("end_time") ? hit["match"]["end_time"].select{|et| !et.blank? }.sort.last : nil,
          "begin_time" => hit["match"].has_key?("begin_time") ? hit["match"]["begin_time"].select{|bt| !bt.blank? }.sort.first : nil
        }
      }
    } if view == 1
    return {
      'hit_count' => hits,
      'document_count' => docs,
      'sampleseed' => response['summary'].has_key?('sampleSeed') ? response['summary']['sampleSeed'] : nil,
      'results' => data.map { |doc|
        {
          "corpus" => doc["docInfo"][CORPUS_TITLE_FIELD],
          "collection" => doc["docInfo"][COLLECTION_TITLE_FIELD],
          "docpid" => doc["docPid"],
          "hit_count" => doc["numberOfHits"],
          "relative_hit_count" => doc.has_key?("numberOfHits") && !hits.blank? ? (doc["numberOfHits"].to_f / hits) * 100 : 0,
          "metadata" => doc["docInfo"]
        }
      }
    } if view == 2
    return {
      'hit_count' => hits,
      'document_count' => docs,
      'group_count' => summary['numberOfGroups'],
      'largest_group_size' => summary['largestGroupSize'],
      'sampleseed' => response['summary'].has_key?('sampleSeed') ? response['summary']['sampleSeed'] : nil,
      'results' => data.map { |group|
        {
          "identity" => group["identity"],
          "#{query.group}" => query.group =~ /H(;|$)/ ? group["identityDisplay"].gsub(/ \-/, '') : group["identityDisplay"],
          "#{view == 8 ? 'hit_count' : 'document_count'}" => group["size"],
          "relative_#{view == 8 ? 'hit_count' : 'document_count'}" => view == 8 ? (group["size"].to_f / hits) * 100 : (group["size"].to_f / docs) * 100
        }
      }
    } if [8,16].include?(view)
  end

  # Return the backend identifier
  def db_type
    return 'blacklab'
  end
  
  # Get node containing total counts for all node labels in index, not implemented for BlackLab
  def get_counter_node
  end

  # Get the filename of the audio file for a specific document ID
  def get_document_audio_file(xmlid)
    data = get_document_metadata(xmlid)["Metadata"]
    if data.has_key?("AudioExportFormat")
      format = data["AudioExportFormat"]
      format = format.kind_of?(Array) ? format[0] : format
      return "#{format}/#{xmlid}.#{format}"
    end
    return "Unknown"
  end

  # Retrieve the paginated content for a document ID. The query pattern is currently not sent to the backend, which effectively disables query highlighting.
  # Currently, the only way to enable it is to retrieve the entire document. We have decided against that approach to save bandwidth.
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
        snippet_length = ENABLE_METADATA_FILTERING ? MetadataHandler.instance.get_document_token_count(xmlid) : 1000
      end
      if sentence_count > index
        sentence = get_document_snippet(xmlid, sentences[index]["start"], snippet_length)
        sdata << sentence["match"]
      end
    end
    
    data["content"] = reformat_content(xmlid, sdata)
    return data
  end

  # Retrieve a paginated document list without a query
  def get_document_list(offset, number)
    return execute_query({
      :url => backend_url+'docs',
      :query => {
        "first" => offset,
        "number" => number,
        "outputformat" => "json"
      }
    })
  end

  # Retrieve a filtered paginated document list without a query
  def get_filtered_document_list(filter, offset, number)
    return execute_query({
      :url => backend_url+'docs',
      :query => ENABLE_METADATA_FILTERING ? {
        "filter" => filter,
        "first" => offset,
        "number" => number,
        "outputformat" => "json"
      } : {
        "patt" => filter,
        "first" => offset,
        "number" => number,
        "outputformat" => "json"
      }
    })
  end

  # Retrieve the entire XML contents of a document ID without a query
  def get_document_xml_content(xmlid)
    return execute_query({
      :url => "#{backend_url}docs/#{xmlid}"
    })
  end

  # Retrieve the entire list of documents for a specific corpus
  def get_corpus_document_list(corpus)
    docs = {}
    offset = 0
    number = 500
    while true do
      resp = execute_query({
        :url => backend_url+'docs',
        :query => {
          "filter" => "#{CORPUS_TITLE_FIELD}:"+corpus,
          "first" => offset,
          "number" => number,
          "outputformat" => "json"
        }
      })
      resp["docs"].each do |doc|
        doc_info = doc["docInfo"]
        docs[doc["docPid"]] = {"token_count" => doc_info["lengthInTokens"], "corpus" => corpus, "collection" => doc_info[COLLECTION_TITLE_FIELD]}
      end
      break unless resp["summary"]["windowHasNext"]
      offset = offset + number
    end
    return docs
  end

  # Retrieve a filtered list of document IDs
  def get_document_id_list(filter)
    docs = []
    offset = 0
    number = 500
    while true do
      resp = execute_query({
        :url => backend_url+'docs',
        :query => {
          "outputformat" => "json",
          "filter" => reformat_filters(filter),
          "first" => offset,
          "number" => number
        }
      })
      resp["docs"].each{ |doc| docs << doc["docPid"] }
      break unless resp["summary"]["windowHasNext"]
      offset = offset + number
    end
    return docs
  end

  # Retrieve the metadata for a specific document ID
  def get_document_metadata(xmlid)
    data = execute_query({
      :url => backend_url+'docs/'+xmlid,
      :query => {
        "outputformat" => "json"
      }
    })
    metadata = {
      "Metadata" => {}
    }
    data['docInfo'].each do |key, value|
      metadata["Metadata"][key] = [value]
    end
    return metadata
  end

  # Get the sentence count for a specific document ID
  def get_document_sentence_count(xmlid)
    data = execute_query({
      :url => backend_url+'hits',
      :query => {
        "outputformat" => "json",
        "patt" => '[xmlid="(p.[0-9]+.)*(s.)*[0-9]+.(w.)*1"]',
        "filter" => "id:"+xmlid,
        "first" => 0,
        "number" => 1
      }
    })["summary"]
    if data["stillCounting"].to_s.eql?('true')
      return get_document_sentence_count(xmlid)
    else
      return data["numberOfHits"]
    end
  end

  # Get all token indices marking sentence starts for a specific document ID
  def get_document_sentence_starts(xmlid, offset, number)
    return execute_query({
      :url => backend_url+'hits',
      :query => {
        "outputformat" => "json",
        "patt" => '[xmlid="(p.[0-9]+.)*(s.)*[0-9]+.(w.)*1"]',
        "filter" => "id:"+xmlid,
        "first" => offset,
        "number" => number
      }
    })
  end

  # Retrieve a content snippet for a specific document ID
  def get_document_snippet(xmlid, hitstart, hitend)
    return execute_query({
      :url => backend_url+'docs/'+xmlid+'/snippet',
      :query => {
        "outputformat" => "json",
        "hitstart" => hitstart,
        "hitend" => hitend,
        "wordsaroundhit" => 0
      }
    })
  end

  # Retrieve simple statistics for a specific document ID
  def get_document_statistics(xmlid)
    token_count = MetadataHandler.instance.get_document_token_count(xmlid)
    contents = get_document_snippet(xmlid, 0, token_count)["match"]
    type_count = contents["word"].uniq.count
    lemma_count = contents["lemma"].uniq.count
    
    return {
      "token_count" => token_count,
      "type_count" => type_count,
      "lemma_count" => lemma_count
    }
  end

  # Retrieve the concatenated contents of a set of filtered documents (for vocabulary growth calculation)
  def get_filtered_content(query)
    contents = []
    get_filtered_document_list(query.filter).keys.each do |doc_id|
      contents = contents + get_document_content(doc_id, query.patt, 0, get_document_sentence_count(doc_id))
    end
    return contents
  end

  # Retrieve a keyword in context
  def get_kwic(docpid, first_index, last_index, size = 50)
    data = execute_query({
      :url => backend_url+'docs/'+docpid+'/snippet',
      :query => {
        "outputformat" => "json",
        "hitstart" => first_index,
        "hitend" => last_index.to_i+1,
        "wordsaroundhit" => size
      }
    })
    return {
      "left_context" => data["left"]["word"].join(" "),
      "hit_text" => data["match"]["word"].join(" "),
      "right_context" => data["right"]["word"].join(" ")
    }
  end

  # Retrieve a list of metadata fields from the backend
  def get_metadata_from_server(number, offset, sort, order)
    resp = execute_query({
      :url => backend_url,
      :query => {
        "outputformat" => "json"
      }
    })
    fields = resp.has_key?("metadataFields") ? resp["metadataFields"] : resp["fieldInfo"]["metadataFields"]
    wanted = number == 0 ? fields : fields.keys[offset..offset+number]
    data = []
    fields.each do |label, field_data|
      group = label.split('_')[0]
      data << { :label => label, :group => group, :key => label.sub(/#{group}_/,'') } if wanted.include?(label)
    end
    return data
  end
  
  # Load metadatum values by label
  def get_metadatum_values_by_label(number, offset, sort, order, label)
    return nil if !label
    resp = execute_query({
      :url => backend_url+'fields/'+label,
      :query => {
        "outputformat" => "json"
      }
    })
    return number == 0 ? resp["fieldValues"].keys : resp["fieldValues"].keys[offset..offset+number]
  end

  # Retrieve a list of PoS head tags and their frequencies from the backend
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
    ph["pos_heads"].sort_by!{|obj| obj[sort] }
    ph["pos_heads"] = ph["pos_heads"].reverse if order.eql?("desc")
    return ph
  end

  # Retrieve the frequency of a specific PoS head tag from the backend
  def get_pos_head_counts(head)
    obj = {
      "label" => head,
      "token_count" => 0
    }
    MetadataHandler.instance.load_corpora.each do |corpus|
      while true do
        resp = execute_query({
          :url => backend_url+"/hits",
          :query => {  
            "outputformat" => "json",
            "patt" => "[pos=\"#{head}.*\"]", 
            "group" => "hit:pos",
            "filter" => "#{CORPUS_TITLE_FIELD}:"+corpus
          }
        })["summary"]
        break unless resp["stillCounting"]
      end
      hit_count = resp["numberOfHits"]
      obj["token_count"] += hit_count
      obj["token_count_"+corpus] = hit_count
    end
    return obj
  end

  # Get PoS tag by label
  def get_pos_tag_by_label(label)
    return reformat_pos_tag({ "label" => label })
  end

  # Get PoS tag feature by label
  def get_pos_tag_features_by_label(label)
    return label.split(/\(/)[1].sub(/\)^/,"").split(/,/).map do |feat|
      { "key" => "unknown", "value" => feat }
    end
  end

  # Get PoS tag type by label
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
      }
    })
    return resp["hitGroups"].map do |hit|
      { "word_type" => hit["identityDisplay"], "token_count" => hit["size"]}
    end
  end

  # Get PoS tags
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
          "sort" => order.eql?("desc") ? "-#{sort}" : sort
        }
      })
      summary = resp["summary"]
      break unless summary["stillCounting"]
    end
    return { 'total' => summary["numberOfGroups"], 'pos_tags' => resp["hitGroups"].map{|hit_group| reformat_pos_tag(hit_group) } }
  end

  # Get human readable name of backend
  def name
    return "BlackLab Server"
  end
  
  # Reformat BlackLab content output to match the format expected by WhiteLab
  def reformat_content(xmlid, data)
    token_index = 0
    reformat = []
    data.each do |sentence|
      arr, token_index = reformat_sentence_content(xmlid, sentence, token_index)
      reformat.push(*arr)
    end
    return reformat
  end

  # Reformat BlackLab sentence content output to match the format expected by WhiteLab
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

  # Reformat BlackLab word content output to match the format expected by WhiteLab
  def reformat_word_content(obj)
    token = { "word_type" => obj[:word], "token_index" => obj[:token_index] }
    ["lemma", "pos", "phonetic", "xmlid", "speaker", "begin_time", "end_time"].each do |field|
      token = reformat_field_content(obj, field, token)
    end
    return token
  end

  # Reformat BlackLab field content output to match the format expected by WhiteLab
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
    elsif obj[:sentence].has_key?(field)
      token[field] = sentence_field
    end
    return token
  end
  
  # Reformat filters to BlackLab format (filter:value)
  def reformat_filters(filters)
    if !filters.blank?
      return filters.gsub('=',':').sub('Metadata_','')
    end
    return ''
  end

  # Reformat group to BlackLab format
  def reformat_group(group)
    if !group.blank?
      if group.start_with?('hit') || group.start_with?('word') || group.start_with?('context')
        return group
      else
        return 'field:'+group.sub('Metadata_','')
      end
    end
    return ''
  end

  # Reformat phonetic to BlackLab format
  def reformat_phonetic(phonetic)
    has_phonetic = false
    
    phonetic.each do |ph|
      if ph.length > 0 
        has_phonetic = true
        break
      end
    end
    
    if has_phonetic
      return phonetic.join(" ")
    else
      return ""
    end
  end

  # Reformat PoS to BlackLab format
  def reformat_pos_tag(pos)
    obj = { "label" => pos.has_key?("label") ? pos["label"] : pos["identityDisplay"], "token_count" => 0 }
    MetadataHandler.instance.load_corpora.each do |corpus|
      pid = obj["label"].gsub(/\(/,'\(').gsub(/\)/,'\)').gsub(/\-/,'\-')
      patt = "[pos=\"#{pid}\"]"
      while true do
        resp = execute_query({
          :url => backend_url+"/hits",
          :query => {  
            "outputformat" => "json",
            "patt" => patt,
            "filter" => "#{CORPUS_TITLE_FIELD}:#{corpus}"
          },
          :headers => headers
        })["summary"]
        break unless resp["stillCounting"]
      end
      hits = resp["numberOfHits"]
      obj["token_count"] += hits
      obj["token_count_#{corpus}"] = hits
    end
    return obj
  end
  
  # Run CQL query on server for set amount of iterations, not implemented for BlackLab
  def run_benchmark_test(cql,iterations)
  end

  # Get the current version of the backend. This will be implemented in BlackLab Server 1.6.0.
  def version
    response = get_headers({ :url => backend_url.sub(/\/[a-zA-Z0-9_]+\/*$/,'') }).parsed_response
    return response["blacklabResponse"].has_key?("blacklabVersion") ? response["blacklabResponse"]["blacklabVersion"] : "1.5.0"
  end
  
end