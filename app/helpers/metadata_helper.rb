# Helper methods for metadata processing
module MetadataHelper
  
  def load_corpora
    YAML.load_file(Rails.root.join('config', 'metadata_'+db_type, 'Corpus.title.yml'))['values'].keys
  end
  
  def get_group_options(view, namespace)
    groups = {}
    if view == 8
      groups['hit'] = []
      groups['left'] = []
      groups['right'] = []
      ['hit','left','right'].each do |position|
        ['text','lemma','pos','phonetic'].each do |annotation|
          groups[position] << [annotation, position.eql?('hit') ? position+'_'+annotation : annotation+'_'+position]
        end
      end
    end
    
    get_metadata_group_options({}, namespace).each do |group, data|
      group = I18n.translate(:"#{group}").capitalize
      if !groups.has_key?(group)
        groups[group] = []
      end
      data.each do |arr|
        field = translate(:"#{arr[0]}")
        groups[group] << [field, arr[1]]
      end
    end
    
    groups
  end
  
  # Get total number of tokens in index
  def get_total_word_token_count
    config = Rails.configuration.x
    tcount = config.total_token_count
    if tcount <= 0
      return set_total_word_token_count
    end
    tcount
  end
  
  # Get total number of tokens in document
  def get_document_token_count(xmlid)
    DOCUMENT_DATA[xmlid]["token_count"]
  end
  
  # Get total number of tokens from metadata selection
  def get_filtered_token_count(filter)
    docs = get_filtered_documents(filter)
    count = 0
    docs.each do |doc|
      count += get_document_token_count(doc)
    end
    count
  end
  
  # Get documents matching metadatum grouped by option value
  def get_filtered_group_composition(option, filter)
    docs = get_filtered_documents(filter)
    docs_included = []
    parts = option.split(/\!*=/)[0]
    group = "Metadata"
    key = parts
    if parts.include?("_")
      group = parts.split('_')[0]
      key = parts.sub(group+'_','')
    end
    result = {}
    # DOCUMENT_METADATA[group][key]
    load_metadata(group,key).each do |value, doc_indices|
      doc_ids = docs & doc_indices.map{|doc_index| DOCUMENT_DATA.keys[doc_index] }
      docs_included += doc_ids
      result[value] = doc_ids
    end
    docs_missing = docs - docs_included
    if docs_missing.any?
      if result.has_key?('Unknown')
        result['Unknown'] = result['Unknown'] + docs_missing
      else
        result['Unknown'] = docs_missing
      end
    end
    final = []
    threads = []
    result.each do |value, ddocs|
      ddocs = ddocs.uniq
      threads << Thread.new do
        count = 0
        ddocs.each do |doc|
          count += get_document_token_count(doc)
        end
        Thread.current[:output] = count > 0 ? { option => value, 'hit_count' => count, 'document_count' => ddocs.size } : {}
      end
    end
    threads.each do |thread|
      thread.join
      output = thread[:output]
      if output.has_key?('hit_count')
        final << output
      end
    end
    final
  end
  
  # Get values for metadatum
  def metadata_values(metadata_obj)
    group = metadata_obj[:group]
    key = metadata_obj[:key]
    if group.eql?(key)
      metadata_obj[:group] = "Metadata"
    end
    # DOCUMENT_METADATA[group][key]
    load_metadata(group,key).keys
  end
  
  # Count values for metadatum
  def metadata_value_count(metadata_obj)
    group = metadata_obj[:group]
    key = metadata_obj[:key]
    if group.eql?(key)
      metadata_obj[:group] = "Metadata"
    end
    # DOCUMENT_METADATA[group][key]
    load_metadata(group,key).keys.length
  end
  
  private
  
  # Get documents matching metadata filters
  def get_filtered_documents(filter)
    doc_ids = DOCUMENT_DATA.keys
    if filter.blank?
      return doc_ids
    else
      filter = filter[1, filter.length - 2]
      filters = {}
      filter.split(')AND(').each do |filter_part|
        parts = filter_part.split(/\!*=/)
        first_part = parts[0]
        second_part = parts[1]
        group = first_part.split('_')[0]
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
      
      docs = []
      filters.each do |group, keys|
        keys.each do |key, values|
          metadata_obj = { :group => group, :key => key }
          ['positive','negative'].each do |set|
            sett = values[set]
            if sett.length > 0
              set_matches = set.eql?('positive') ? get_positive_filter_value_matches(metadata_obj, sett) : get_negative_filter_value_matches(metadata_obj, sett)
              set_matches = set_matches.map{|doc_index| doc_ids[doc_index] }
              docs = docs.length == 0 ? set_matches : docs & set_matches
            end
          end
        end
      end
      return docs.uniq
    end
  end
  
  # Get documents not matching metadatum value
  def get_negative_filter_value_matches(metadata_obj, values)
    group = metadata_obj[:group]
    key = metadata_obj[:key]
    if group.eql?(key)
      metadata_obj[:group] = "Metadata"
    end
    docs = []
    # DOCUMENT_METADATA[group][key]
    load_metadata(metadata_obj).each do |value, doc_indices|
      if !values.include?(value)
        docs.push(*doc_indices)
      end
    end
    docs
  end
  
  # Get documents matching metadatum value
  def get_positive_filter_value_matches(metadata_obj, values)
    group = metadata_obj[:group]
    key = metadata_obj[:key]
    if group.eql?(key)
      metadata_obj[:group] = "Metadata"
    end
    # DOCUMENT_METADATA[group][key]
    load_metadata(metadata_obj)[values[0]]
  end
  
  def set_total_word_token_count
    tcount = get_filtered_token_count(nil)
    Rails.configuration.x.total_token_count = tcount
    return tcount
  end
  
  # Strip quotes from metadatum value
  def strip_value(value)
    value.chomp('"').reverse.chomp('"').reverse
  end
  
end