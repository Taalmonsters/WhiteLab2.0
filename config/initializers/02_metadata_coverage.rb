backend = WhitelabBackend.instance
metadata_dir = Rails.root.join('config','metadata_'+backend.get_backend_type).to_s

if !File.directory?(metadata_dir)
  Dir.mkdir metadata_dir
end

doc_file = metadata_dir+'/documents.yml'

logger = Logger.new STDOUT
logger.formatter = Logger::Formatter.new
logger.info "Loading documents"

if !File.exists?(doc_file)
  logger.info "Retrieving document list from backend '"+backend.get_backend_type+"'"
  docs = backend.get_document_list
  File.open(doc_file, 'w') { |f| YAML.dump({ "documents" => docs }, f) }
end
  
::DOCUMENT_DATA = YAML.load_file(doc_file)["documents"]
logger.info "Finished loading documents"

if Dir[metadata_dir+'/*.yml'].length < 2
  logger.info "Creating metadata coverage configuration file"
  
  logger.info "Loading document metadata"
  threads = []
  i = DOCUMENT_DATA.length / 80 + 1
  DOCUMENT_DATA.keys.in_groups_of(i) do |subset|
    threads << Thread.new do
      subset.each_with_index do |xmlid, d|
        doc_data = DOCUMENT_DATA[xmlid]
        if d > 0 && d % 2000 == 0
          logger.info "Thread "+Thread.current.object_id.to_s+" processed "+d.to_s+" out of "+i.to_s+" docs"
        end
        if !doc_data.blank?
          doc_tmp_file = Rails.root.join('tmp','data').to_s+'/'+xmlid+'.js'
          if doc_data.has_key?("token_count") && !doc_data["token_count"].blank? && doc_data["token_count"] > 0 && !File.exists?(doc_tmp_file)
            doc_metadata = {}
            doc_metadata["metadata"] = backend.get_document_metadata(xmlid)
            doc_metadata["token_count"] = doc_data["token_count"]
            doc_metadata["corpus"] = doc_data["corpus"]
            doc_metadata["collection"] = doc_data["collection"]
            if !doc_metadata.has_key?("document_xmlid")
              doc_metadata["document_xmlid"] = xmlid
            end
            if !File.directory?(Rails.root.join('tmp','data').to_s)
              Dir.mkdir Rails.root.join('tmp','data').to_s
            end
            File.open(doc_tmp_file, "w+") do |f|
              f.puts(doc_metadata.to_json)
            end
          end
        end
      end
    end
  end
  threads.each(&:join)
  
  logger.info "Adding document ids to metadata values"
  metadata = {}
  metadata["Corpus"] = {}
  metadata["Corpus"]["title"] = {}
  metadata["Collection"] = {}
  metadata["Collection"]["title"] = {}
  if backend.get_backend_type.eql?('blacklab')
    metadata["Metadata"] = {}
  end
  files = Dir[Rails.root.join('tmp','data').to_s+'/*.js']
  files.each_with_index do |file, f|
    if f > 0 && f % 100000 == 0
      logger.info "Processed "+f.to_s+" out of "+files.length.to_s+" documents"
    end
    content = File.read(file)
    if content.length > 0
      doc_data = JSON.parse(content)
      if !metadata["Corpus"]["title"].has_key?(doc_data["corpus"])
        metadata["Corpus"]["title"][doc_data["corpus"]] = []
      end
      metadata["Corpus"]["title"][doc_data["corpus"]] << doc_data["document_xmlid"]
      if !metadata["Collection"]["title"].has_key?(doc_data["collection"])
        metadata["Collection"]["title"][doc_data["collection"]] = []
      end
      metadata["Collection"]["title"][doc_data["collection"]] << doc_data["document_xmlid"]
      
      if backend.get_backend_type.eql?('blacklab')
        doc_data["metadata"]["Metadata"].each do |key, value|
          if !metadata["Metadata"].has_key?(key)
            metadata["Metadata"][key] = {}
          end
          if !metadata["Metadata"][key].has_key?(value[0])
            metadata["Metadata"][key][value[0]] = []
          end
          metadata["Metadata"][key][value[0]] << doc_data["document_xmlid"]
        end
      elsif backend.get_backend_type.eql?('neo4j')
        doc_data["metadata"].each do |group, keys|
          if !metadata.has_key?(group)
            metadata[group] = {}
          end
          keys.each do |key, values|
            if !metadata[group].has_key?(key)
              metadata[group][key] = {}
            end
            values.each do |value|
              if !metadata[group][key].has_key?(value)
                metadata[group][key][value] = []
              end
              metadata[group][key][value] << doc_data["document_xmlid"]
            end
          end
        end
      end
    end
    File.delete(file)
  end
  # save all data to configuration files
  logger.info  "Writing metadata coverage to configuration files"
  # File.open(coverage_config, 'w') { |f| YAML.dump({ "coverage" => metadata }, f) }
  
  threads = []
  metadata.each do |group, keys|
    threads << Thread.new do
      keys.each do |key, values|
        key_file = metadata_dir+'/'+group+'.'+key+'.yml'
        if !File.exists?(key_file)
          File.open(key_file, 'w', external_encoding: 'ASCII-8BIT') { |f| YAML.dump({ "values" => metadata[group][key] }, f) }
        end
      end
    end
  end
  threads.each(&:join)
end

logger.info "Loading metadata"
metadata = {}
Dir[metadata_dir+'/*.yml'].each do |file|
  if !file.end_with?('documents.yml')
    base = file.sub(metadata_dir+'/','').sub('.yml','')
    group = base.split('.')[0]
    key = base.split('.')[1]
    if !metadata.has_key?(group)
      metadata[group] = {}
    end
    metadata[group][key] = YAML.load_file(file)["values"]
  end
end
::DOCUMENT_METADATA = metadata
logger.info "Finished loading metadata"
