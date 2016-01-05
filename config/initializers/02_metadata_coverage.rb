logger = Logger.new STDOUT
logger.formatter = Logger::Formatter.new
doc_file = Rails.root.join('config','metadata').to_s+'/documents.yml'
logger.info "Loading documents"
if !File.exists?(doc_file)
  data = `curl --header "Authorization: Basic bmVvNGo6Nzc0M21vbnN0ZXJzODE=" -H accept:application/json -H content-type:application/json -d '{"statements": [{ "statement": "MATCH (d:Document) MATCH d<-[:HAS_DOCUMENT]->(cc:Collection) MATCH cc<-[:HAS_COLLECTION]-(c:Corpus) RETURN DISTINCT d.xmlid AS xmlid, d.token_count AS token_count, c.title AS corpus, cc.title AS collection;" }]}' http://localhost:7474/db/data/transaction/commit`;
  data = JSON.parse(data)
  docs = {}
  data["results"][0]["data"].each do |x|
    docs[x["row"][0]] = {"token_count" => x["row"][1], "corpus" => x["row"][2], "collection" => x["row"][3]}
  end
  File.open(doc_file, 'w') { |f| YAML.dump({ "documents" => docs }, f) }
end
  
::DOCUMENT_DATA = YAML.load_file(doc_file)["documents"]
logger.info "Finished loading documents"

if Dir[Rails.root.join('config','metadata').to_s+'/*.yml'].length < 2
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
          # doc_row.each do |xmlid, doc_data|
            doc_tmp_file = Rails.root.join('tmp','data').to_s+'/'+xmlid+'.js'
            if doc_data.has_key?("token_count") && !doc_data["token_count"].blank? && doc_data["token_count"] > 0 && !File.exists?(doc_tmp_file)
              doc_metadata = HTTParty.get('http://localhost:7474/whitelab/search/docs/'+xmlid+'/metadata',
                :headers => { 'Content-Type' => 'application/json',
                              'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } ).parsed_response
              doc_metadata["token_count"] = doc_data["token_count"]
              doc_metadata["corpus"] = doc_data["corpus"]
              doc_metadata["collection"] = doc_data["collection"]
              File.open(doc_tmp_file, "w+") do |f|
                f.puts(doc_metadata.to_json)
              end
            end
          # end
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
    File.delete(file)
  end
  # save all data to configuration files
  logger.info  "Writing metadata coverage to configuration files"
  # File.open(coverage_config, 'w') { |f| YAML.dump({ "coverage" => metadata }, f) }
  
  threads = []
  metadata.each do |group, keys|
    threads << Thread.new do
      keys.each do |key, values|
        key_file = Rails.root.join('config','metadata').to_s+'/'+group+'.'+key+'.yml'
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
Dir[Rails.root.join('config','metadata').to_s+'/*.yml'].each do |file|
  if !file.end_with?('documents.yml')
    base = file.sub(Rails.root.join('config','metadata').to_s+'/','').sub('.yml','')
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
