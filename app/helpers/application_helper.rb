# General helper methods
module ApplicationHelper
  
  @@BACKEND = WhitelabBackend.instance
  
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
    
    metadata = YAML.load_file(Rails.root.join('config').to_s+'/metadata_'+@@BACKEND.get_backend_type+'.yml')
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
