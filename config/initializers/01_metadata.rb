backend = WhitelabBackend.instance
logger = Logger.new STDOUT
logger.formatter = Logger::Formatter.new

metadata_config = Rails.root.join('config').to_s+'/metadata_'+backend.get_backend_type+'.yml'

if !File.exists?(metadata_config)
  metadata = {}
  logger.info  "Creating metadata configuration file for backend '"+backend.get_backend_type+"'"
  
  metadata["Corpus"] = {}
  metadata["Corpus"]["title"] = {}
  metadata["Corpus"]["title"]["group"] = "Corpus"
  metadata["Corpus"]["title"]["key"] = "title"
  metadata["Corpus"]["title"]["label"] = "Corpus_title"
  metadata["Corpus"]["title"]["value_count"] = 0
  metadata["Corpus"]["title"]["values"] = []
  metadata["Collection"] = {}
  metadata["Collection"]["title"] = {}
  metadata["Collection"]["title"]["group"] = "Collection"
  metadata["Collection"]["title"]["key"] = "title"
  metadata["Collection"]["title"]["label"] = "Collection_title"
  metadata["Collection"]["title"]["value_count"] = 0
  metadata["Collection"]["title"]["values"] = []
  
  if backend.get_backend_type.eql?('blacklab')
    metadata["Metadata"] = {}
  end
  
  # load available corpora from server
  logger.info  "Loading corpora from server"
  cdata = backend.get_corpus_titles
  
  cdata.each do |corpus|
    metadata["Corpus"]["title"]["values"] << corpus
    metadata["Corpus"]["title"]["value_count"] = metadata["Corpus"]["title"]["value_count"] + 1
  end
  
  # load available collections from server
  logger.info  "Loading collections from server"
  cdata = backend.get_collection_titles
  
  cdata.each do |collection|
    metadata["Collection"]["title"]["values"] << collection
    metadata["Collection"]["title"]["value_count"] = metadata["Collection"]["title"]["value_count"] + 1
  end
  
  # load available metadata fields from server
  logger.info  "Loading metadata from server"
  data = backend.get_metadata_from_server(0, 0, nil, nil)
  
  # loop through fields
  data.each do |metadatum|
    if backend.get_backend_type.eql?('blacklab')
      # load field values from server
      logger.info  "Loading field values from server (label: "+metadatum["fieldName"]+")"
      mvalues = backend.get_metadatum_values_by_label(0, 0, nil, nil, metadatum["fieldName"])
      metadata["Metadata"][metadatum["fieldName"]] = {
        "group" => "Metadata",
        "key" => metadatum["fieldName"],
        "label" => metadatum["fieldName"],
        "display_name" => metadatum["displayName"],
        "values" => mvalues,
        "value_count" => mvalues.length,
        "value_type" => metadatum["type"].downcase
      }
    elsif backend.get_backend_type.eql?('neo4j')
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
      values = backend.get_metadatum_values_by_label(0, 0, sort, order, metadatum["data"]["label"])
      values.each do |value|
        metadata[metadatum["data"]["group"]][metadatum["data"]["key"]]["values"].push(value["value"])
      end
    end
  end
  # save all data to configuration file
  logger.info  "Writing metadata to configuration file"
  File.open(metadata_config, 'w', external_encoding: 'ASCII-8BIT') { |f| YAML.dump({ "metadata" => metadata }, f) }
end
