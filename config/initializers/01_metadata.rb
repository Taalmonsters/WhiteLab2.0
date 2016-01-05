metadata_config = Rails.root.join('config').to_s+'/metadata.yml'
if !File.exists?(metadata_config)
  logger = Logger.new STDOUT
  logger.formatter = Logger::Formatter.new
  metadata = {}
  logger.info  "Creating metadata configuration file"
  
  # load available corpora from server
  logger.info  "Loading corpora from server"
  cdata = HTTParty.get('http://localhost:7474/db/data/label/Corpus/nodes',
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
  
  cdata.each do |corpus|
    if !metadata.has_key?("Corpus")
      metadata["Corpus"] = {}
    end
    if !metadata["Corpus"].has_key?("title")
      metadata["Corpus"]["title"] = {}
      metadata["Corpus"]["title"]["values"] = []
    end
    metadata["Corpus"]["title"]["values"] << corpus["data"]["title"]
  end
  
  # load available collections from server
  logger.info  "Loading collections from server"
  cdata = HTTParty.get('http://localhost:7474/db/data/label/Collection/nodes',
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
  
  cdata.each do |collection|
    if !metadata.has_key?("Collection")
      metadata["Collection"] = {}
    end
    if !metadata["Collection"].has_key?("title")
      metadata["Collection"]["title"] = {}
      metadata["Collection"]["title"]["values"] = []
    end
    metadata["Collection"]["title"]["values"] << collection["data"]["title"]
  end
  
  # load available metadata fields from server
  logger.info  "Loading metadata from server"
  data = HTTParty.get('http://localhost:7474/db/data/label/Metadatum/nodes',
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
  
  # loop through fields
  data.each do |metadatum|
    # store fields per group
    if !metadata.has_key?(metadatum["data"]["group"])
      metadata[metadatum["data"]["group"]] = {}
    end
    if !metadata[metadatum["data"]["group"]].has_key?(metadatum["data"]["key"])
      # store field data as is and create empty array to hold field values
      metadata[metadatum["data"]["group"]][metadatum["data"]["key"]] = metadatum["data"]
      metadata[metadatum["data"]["group"]][metadatum["data"]["key"]]["values"] = []
    else
      # combine fields with the same group and key
      metadatum["data"].each do |prop, value|
        if prop.include?('count')
          metadata[metadatum["data"]["group"]][metadatum["data"]["key"]][prop] += metadatum["data"][prop]
        end
      end
    end
    # load field values from server
    logger.info  "Loading field values from server (label: "+metadatum["data"]["label"]+")"
    sort = "value"
    order = "asc"
    count = false
    # only store the top METADATUM_VALUES_MAX values for fields with value_count > METADATUM_VALUES_MAX (defined in config/application.rb)
    if metadatum["data"]["value_count"] > METADATUM_VALUES_MAX
      logger.info "Value count for "+metadatum["data"]["label"]+" ("+metadatum["data"]["value_count"].to_s+") exceeds METADATUM_VALUES_MAX ("+METADATUM_VALUES_MAX.to_s+", defined in config/application.rb)"
      logger.info "Only the top "+METADATUM_VALUES_MAX.to_s+" values will be retrieved."
      sort = "document_count"
      order = "desc"
      count = true
    end
    values = HTTParty.get('http://localhost:7474/whitelab/search/metadata/'+metadatum["data"]["label"]+'/values', timeout: NEO4J_TIMEOUT_SECONDS,
      :query => { "number" => METADATUM_VALUES_MAX, 
                 "offset" => 0,
                 "sort" => sort, 
                 "order" => order,
                 "count" => count
               },
      :headers => { 'Content-Type' => 'application/json',
                    'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )["values"]
    values.each do |value|
      metadata[metadatum["data"]["group"]][metadatum["data"]["key"]]["values"].push(value["value"])
    end
  end
  # save all data to configuration file
  logger.info  "Writing metadata to configuration file"
  File.open(metadata_config, 'w', external_encoding: 'ASCII-8BIT') { |f| YAML.dump({ "metadata" => metadata }, f) }
end
