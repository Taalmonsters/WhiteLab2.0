# Helper methods for metadata processing
module MetadataHelper
  
  def load_corpora
    values, vcount = load_values({ :group => 'Corpus', :key => 'title' })
    values
  end
  
  def load_values(metadata_obj)
    data = YAML.load_file(Rails.root.join('config', "metadata_#{db_type}.yml"))['metadata'][metadata_obj[:group]][metadata_obj[:key]]
    return data['values'], data['value_count']
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
        field = I18n.translate(:"#{arr[0]}")
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
    set_size = (docs.size / 10).round + 1
    threads = []
    docs.each_slice(set_size) do |set|
      threads << Thread.new do
        Thread.current[:output] = set.map {|doc| get_document_token_count(doc)}.reduce(0, :+)
      end
    end
    count = 0
    threads.each do |thread|
      thread.join
      count += thread[:output]
    end
    count
  end
  
  # Get documents matching metadatum grouped by option value
  def get_filtered_group_composition(option, filter)
    docs_included = get_filtered_documents(filter)
    set_size = (docs_included.size / 10).round + 1
    threads = []
    docs_with_counts = {}
    docs_included.each_slice(set_size) do |set|
      threads << Thread.new do
        output = {}
        set.each do |doc|
          output[doc] = get_document_token_count(doc)
        end
        Thread.current[:output] = output
      end
    end
    threads.each do |thread|
      thread.join
      docs_with_counts.merge!(thread[:output])
    end
    docs_included = []
    first_part = option.split(/\!*=/)[0]
    group = "Metadata"
    key = first_part
    if first_part.include?("_")
      group = first_part.split('_')[0]
      key = first_part.sub(group+'_','')
    end
    result = {}
    load_metadata({ :group => group, :key => key }).each do |value, doc_indices|
      doc_ids = docs_with_counts.keys & doc_indices.map{|doc_index| DOCUMENT_DATA.keys[doc_index] }
      docs_included += doc_ids
      result[value] = { option => value, 'hit_count' => docs_with_counts.select{|doc, count| doc_ids.include?(doc) }.map{|doc, count| count }.reduce(0, :+), 'document_count' => doc_ids.size }
    end
    docs_missing = docs_with_counts.keys - docs_included
    docs = nil
    if docs_missing.any?
      result['Unknown'] = { option => 'Unknown', 'hit_count' => 0, 'document_count' => 0 } unless result.has_key?('Unknown')
      result['Unknown']['hit_count'] += docs_with_counts.select{|doc, count| docs_missing.include?(doc) }.map{|doc, count| count }.reduce(0, :+)
      result['Unknown']['document_count'] += docs_missing.size
    end
    return result.values.flatten.select{|x| x['hit_count'] > 0}
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