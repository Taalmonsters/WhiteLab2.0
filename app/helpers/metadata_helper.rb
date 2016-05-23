module MetadataHelper
  include ApplicationHelper
  
  def load_corpora
    YAML.load_file(Rails.root.join('config', 'metadata_'+WhitelabBackend.instance.get_backend_type, 'Corpus.title.yml'))['values'].keys
  end
  
  def get_group_options(v, namespace)
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
    # groups[translate(:"data_labels.keys.corpus").capitalize] = []
    # groups[translate(:"data_labels.keys.corpus").capitalize] << [translate(:"data_labels.keys.corpus").capitalize+' '+translate(:"navigation.keys.title").capitalize, 'Corpus_title']
    # groups[translate(:"data_labels.keys.collection").capitalize] = []
    # groups[translate(:"data_labels.keys.collection").capitalize] << [translate(:"data_labels.keys.collection").capitalize+' '+translate(:"navigation.keys.title").capitalize, 'Collection_title']
    
    WhitelabBackend.instance.get_metadata_group_options({}, namespace).each do |group, data|
      g = translate(:"#{group}").capitalize
      if !groups.has_key?(g)
        groups[g] = []
      end
      data.each do |arr|
        f = translate(:"#{arr[0]}")
        groups[g] << [f, arr[1]]
      end
    end
    
    groups
  end
  
  # Get total number of tokens in index
  def get_total_word_token_count
    if Rails.configuration.x.total_token_count <= 0
      Rails.configuration.x.total_token_count = get_filtered_token_count(nil)
    end
    Rails.configuration.x.total_token_count
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
  
  def load_metadata(group, key)
    file = Rails.root.join('config', 'metadata_'+WhitelabBackend.instance.get_backend_type, group+'.'+key+'.yml')
    if File.exists?(file)
      return YAML.load_file(file)['values']
    else
      return {}
    end
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
    load_metadata(group,key).each do |value, d|
      result[value] = docs & d.map{|x| DOCUMENT_DATA.keys[x] }
      if docs_included.length == 0
        docs_included = result[value]
      else
        docs_included = docs_included + result[value]
      end
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
    result.each do |value, d|
      threads << Thread.new do
        count = 0
        d.uniq.each do |doc|
          count += get_document_token_count(doc)
        end
        if count > 0
          Thread.current[:output] = { option => value, 'hit_count' => count, 'document_count' => d.uniq.size }
        else
          Thread.current[:output] = {}
        end
      end
    end
    threads.each do |t|
      t.join
      if t[:output].has_key?('hit_count')
        final << t[:output]
      end
    end
    final
  end
  
  # Get documents matching metadata filters
  def get_filtered_documents(filter)
    docs = []
    if filter.blank?
      docs = DOCUMENT_DATA.keys
    else
      filter = filter[1, filter.length - 2]
      filters = {}
      filter.split(')AND(').each do |f|
        parts = f.split(/\!*=/)
        group = parts[0].split('_')[0]
        if !filters.has_key?(group)
          filters[group] = {}
        end
        key = parts[0].sub(group+'_','')
        if !filters[group].has_key?(key)
          filters[group][key] = { 'positive' => [], 'negative' => []}
        end
        value = strip_value(parts[1])
        if f.eql?(parts[0]+'!='+parts[1])
          filters[group][key]['negative'] << value
        else
          filters[group][key]['positive'] << value
        end
      end
      
      filters.each do |group, keys|
        keys.each do |key, values|
          if values['positive'].length > 0
            values['positive'].each do |value|
              if docs.length == 0
                docs = get_positive_filter_value_matches(group, key, value).map{|x| DOCUMENT_DATA.keys[x] }
              else
                docs = docs & get_positive_filter_value_matches(group, key, value).map{|x| DOCUMENT_DATA.keys[x] }
              end
            end
          elsif values['negative'].length > 0
            if docs.length == 0
              docs = get_negative_filter_value_matches(group, key, values['negative']).map{|x| DOCUMENT_DATA.keys[x] }
            else
              docs = docs & get_negative_filter_value_matches(group, key, values['negative']).map{|x| DOCUMENT_DATA.keys[x] }
            end
          end
        end
      end
    end
    docs.uniq
  end
  
  # Strip quotes from metadatum value
  def strip_value(value)
    value.chomp('"').reverse.chomp('"').reverse
  end
  
  # Get documents not matching metadatum value
  def get_negative_filter_value_matches(group, key, values)
    if group.eql?(key)
      group = "Metadata"
    end
    docs = []
    # DOCUMENT_METADATA[group][key]
    load_metadata(group,key).each do |value, d|
      if !values.include?(value)
        docs.push(*d)
      end
    end
    docs
  end
  
  # Get documents matching metadatum value
  def get_positive_filter_value_matches(group, key, value)
    if group.eql?(key)
      group = "Metadata"
    end
    # DOCUMENT_METADATA[group][key]
    load_metadata(group,key)[value]
  end
  
  # Get values for metadatum
  def metadata_values(group,key)
    if group.eql?(key)
      group = "Metadata"
    end
    # DOCUMENT_METADATA[group][key]
    load_metadata(group,key).keys
  end
  
  # Count values for metadatum
  def metadata_value_count(group,key)
    if group.eql?(key)
      group = "Metadata"
    end
    # DOCUMENT_METADATA[group][key]
    load_metadata(group,key).keys.length
  end
  
end