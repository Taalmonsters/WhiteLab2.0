# General helper methods
module ApplicationHelper
  include DatabaseHelper
  
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
  
  # Get documents matching metadatum grouped by option value
  def get_filtered_group_composition(option, filter)
    docs = get_filtered_documents(filter)
    docs_included = []
    parts = option.split(/\!*=/)[0]
    group = parts.split('_')[0]
    key = parts.sub(group+'_','')
    data = DOCUMENT_METADATA[group][key]
    result = {}
    data.each do |value, d|
      result[value] = docs & d
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
        d.each do |doc|
          count += get_document_token_count(doc)
        end
        if count > 0
          Thread.current[:output] = { option => value, 'hit_count' => count, 'document_count' => d.size }
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
      DOCUMENT_METADATA["Corpus"]["title"].each do |corpus, data|
        if docs.length == 0
          docs = data
        else
          docs = docs + data
        end
      end
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
                docs = get_positive_filter_value_matches(group, key, value)
              else
                docs = docs & get_positive_filter_value_matches(group, key, value)
              end
            end
          elsif values['negative'].length > 0
            if docs.length == 0
              docs = get_negative_filter_value_matches(group, key, values['negative'])
            else
              docs = docs & get_negative_filter_value_matches(group, key, values['negative'])
            end
          end
        end
      end
    end
    docs
  end
  
  # Strip quotes from metadatum value
  def strip_value(value)
    value.chomp('"').reverse.chomp('"').reverse
  end
  
  # Get documents not matching metadatum value
  def get_negative_filter_value_matches(group, key, values)
    docs = []
    DOCUMENT_METADATA[group][key].each do |value, d|
      if !values.include?(value)
        docs.push(*d)
      end
    end
    docs
  end
  
  # Get documents matching metadatum value
  def get_positive_filter_value_matches(group, key, value)
    DOCUMENT_METADATA[group][key][value]
  end
  
  # Get values for metadatum
  def metadata_values(group,key)
    DOCUMENT_METADATA[group][key].keys
  end
  
  # Count values for metadatum
  def metadata_value_count(group,key)
    DOCUMENT_METADATA[group][key].keys.length
  end
  
  # Load list of all languages
  def load_all_languages
    data = []
    YAML.load_file(Rails.root.join('config').to_s+'/languages.yml')['languages'].each do |k,v|
      data << [k,v]
    end
    data
  end
  
  # Load translation data for all languages
  def load_available_languages
    data = []
    dir = Rails.root.join('config', 'locales').to_s
    YAML.load_file(Rails.root.join('config').to_s+'/languages.yml')['languages'].each do |k,v|
      if File.exist?(dir+'/'+v.to_s+'.yml')
        data << [k,v]
      end
    end
    data
  end
  
  # Load translated home page content from configuration file
  def load_home_page_data
    data = {}
    dir = Rails.root.join('config', 'locales', 'home_page').to_s
    files = Dir.glob(dir+"/*.yml")
    files.each do |yml|
      lang = File.basename(yml, ".yml")
      data[lang] = YAML.load_file(yml)[lang]
    end
    data
  end
  
  # Load translated help page content from configuration file
  def load_help_page_data
    data = {}
    dir = Rails.root.join('config', 'locales', 'help_page').to_s
    files = Dir.glob(dir+"/*.yml")
    files.each do |yml|
      lang = File.basename(yml, ".yml")
      data[lang] = YAML.load_file(yml)[lang]
    end
    data
  end
  
  # Load data for label and keys translations
  def load_translation_data
    data = {}
    dir = Rails.root.join('config', 'locales').to_s
    files = Dir.glob(dir+"/*.yml")
    files.each do |yml|
      lang = File.basename(yml, ".yml")
      data[lang] = YAML.load_file(yml)[lang]
      if !data[lang].has_key?('metadata_groups')
        data[lang]['metadata_groups'] = {
          'title' => 'Metadata groups',
          'description' => 'Translations of metadata group labels',
          'keys' => {}
        }
        save_language(lang,data[lang])
      end
      if !data[lang].has_key?('metadata_keys')
        data[lang]['metadata_keys'] = {
          'title' => 'Metadata keys',
          'description' => 'Translations of metadata key labels',
          'keys' => {}
        }
        save_language(lang,data[lang])
      end
    end
    
    metadata = YAML.load_file(Rails.root.join('config').to_s+'/metadata.yml')
    changed = false
    
    metadata['metadata'].each do |group, keys|
      data.each do |lang, ldata|
        if !ldata['metadata_groups']['keys'].has_key?(group)
          ldata['metadata_groups']['keys'][group] = group
          changed = true
        end
      end
      keys.each do |key, kdata|
        data.each do |lang, ldata|
          if !ldata['metadata_keys']['keys'].has_key?(key)
            ldata['metadata_keys']['keys'][key] = key
            changed = true
          end
        end
      end
    end
    
    if changed
      @languages = data
      save_languages
    end
    
    data
  end
  
  # Save translation data for all languages
  def save_languages
    @languages.each do |lang,data|
      save_language(lang,data)
    end
  end
  
  # Save translation data for language to configuration file
  def save_language(lang,data)
    new_data = {
      lang => data
    }
    File.open(Rails.root.join('config', 'locales').to_s+"/"+lang+".yml", 'w', external_encoding: 'utf-8') { |f| YAML.dump(new_data, f) }
  end
  
  # Save home page translation to configuration file
  def save_home_page(lang,data)
    new_data = {
      lang => {
        "home_page" => data
      }
    }
    File.open(Rails.root.join('config', 'locales', 'home_page').to_s+"/"+lang+".yml", 'w', external_encoding: 'ASCII-8BIT') { |f| YAML.dump(new_data, f) }
  end
  
  # Save help page translation to configuration file
  def save_help_page(lang,data)
    new_data = {
      lang => {
        "help_page" => data
      }
    }
    File.open(Rails.root.join('config', 'locales', 'help_page').to_s+"/"+lang+".yml", 'w', external_encoding: 'ASCII-8BIT') { |f| YAML.dump(new_data, f) }
  end
  
end
