# General helper methods
module ApplicationHelper
  
  # Load list of all languages
  def load_all_languages
    data = []
    YAML.load_file(Rails.root.join('config').to_s+'/languages.yml')['languages'].each do |key,value|
      data << [key,value]
    end
    data
  end
  
  # Load translation data for all languages
  def load_available_languages
    data = []
    rroot = Rails.root
    YAML.load_file(rroot.join('config').to_s+'/languages.yml')['languages'].each do |key,value|
      if File.exist?(rroot.join('config', 'locales').to_s+'/'+value.to_s+'.yml')
        data << [key,value]
      end
    end
    data
  end
  
  # Load translated info page content from configuration file
  def load_info_page_data
    load_page_data('info')
  end
  
  # Load translated help page content from configuration file
  def load_help_page_data
    load_page_data('help')
  end
  
  def load_page_data(page)
    data = {}
    files = Dir.glob(Rails.root.join('config', 'locales', page+'_page').to_s+"/*.yml")
    files.each do |yml|
      lang = File.basename(yml, ".yml")
      data[lang] = YAML.load_file(yml)[lang]
    end
    data
  end
  
  # Load data for label and keys translations
  def load_translation_data
    data = {}
    rroot = Rails.root
    files = Dir.glob(rroot.join('config', 'locales').to_s+"/*.yml")
    files.each do |yml|
      lang = File.basename(yml, ".yml")
      lang_data = YAML.load_file(yml)[lang]
      if ENABLE_METADATA_FILTERING
        ['group','key'].each do |set|
          if !lang_data.has_key?("metadata_#{set}s")
            lang_data["metadata_#{set}s"] = {
              'title' => "Metadata #{set}s",
              'description' => "Translations of metadata #{set} labels",
              'keys' => {}
            }
            save_language({ :lang => lang, :data => lang_data })
          end
        end
      end
      data[lang] = lang_data
    end
    
    changed = false
    
    if ENABLE_METADATA_FILTERING
      MetadataHandler.instance.metadata.each do |label, metadatum|
        data.each do |lang, ldata|
          ldata, changed_group = set_metadata_translation(ldata, 'group', metadatum['group'])
          ldata, changed_key = set_metadata_translation(ldata, 'key', metadatum['key'])
          changed = changed ? changed : changed_group || changed_key
        end
      end
    end
    
    if changed
      @languages = data
      save_languages
    end
    
    data
  end
  
  def set_metadata_translation(ldata, key, value)
    ldata["metadata_#{key}s"]['keys'] = {} if !ldata["metadata_#{key}s"]['keys']
    keys = ldata["metadata_#{key}s"]['keys']
    if !keys.has_key?(value)
      keys[value] = value
      return ldata, true
    end
    return ldata, false
  end
  
  # Save translation data for all languages
  def save_languages
    @languages.each do |lang,data|
      save_language({ :lang => lang, :data => data })
    end
  end
  
  # Save translation data for language to configuration file
  def save_language(lang_obj)
    lang = lang_obj[:lang]
    new_data = {
      lang => lang_obj[:data]
    }
    File.open(Rails.root.join('config', 'locales').to_s+"/"+lang+".yml", 'w', external_encoding: 'utf-8') { |file| YAML.dump(new_data, file) }
  end
  
  # Save info page translation to configuration file
  def save_info_page(lang_obj)
    save_page('info', lang_obj)
  end
  
  def save_page(page, lang_obj)
    lang = lang_obj[:lang]
    new_data = {
      lang => {
        "#{page}_page" => data
      }
    }
    File.open(Rails.root.join('config', 'locales', "#{page}_page").to_s+"/"+lang+".yml", 'w', external_encoding: 'ASCII-8BIT') { |file| YAML.dump(new_data, file) }
  end
  
end
