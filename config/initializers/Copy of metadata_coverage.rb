# coverage_config = Rails.root.join('config').to_s+'/coverage.yml'
# if !File.exists?(coverage_config)
  # logger = Logger.new STDOUT
  # logger.formatter = Logger::Formatter.new
  # metadata = {}
  # metadata["Corpus"] = {}
  # metadata["Corpus"]["title"] = {}
  # metadata["Collection"] = {}
  # metadata["Collection"]["title"] = {}
  # logger.info  "Creating metadata coverage configuration file"
#   
  # # load available collections from server
  # logger.info  "Loading collections from server"
  # cdata = HTTParty.get('http://localhost:7474/db/data/label/Collection/nodes',
      # :headers => { 'Content-Type' => 'application/json',
                    # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
#   
  # cdata.each do |collection|
    # logger.info  "Processing collection "+collection["data"]['title']
    # metadata["Collection"]["title"][collection["data"]["title"]] = []
    # # retrieve corpus for collection
    # corpora = HTTParty.get(collection["incoming_relationships"],
        # :headers => { 'Content-Type' => 'application/json',
                      # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    # corpus = HTTParty.get(corpora[0]["start"],
        # :headers => { 'Content-Type' => 'application/json',
                      # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    # if !metadata["Corpus"]["title"].has_key?(corpus["data"]["title"])
      # metadata["Corpus"]["title"][corpus["data"]["title"]] = []
    # end
    # documents = HTTParty.get(collection["outgoing_relationships"],
        # :headers => { 'Content-Type' => 'application/json',
                      # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
    # documents.each do |doc_rel|
      # document = HTTParty.get(doc_rel["end"],
          # :headers => { 'Content-Type' => 'application/json',
                        # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
      # metadata["Collection"]["title"][collection["data"]["title"]] << { "xmlid" => document["data"]["xmlid"], "token_count" => document["data"]["token_count"] }
      # if !metadata["Corpus"]["title"][corpus["data"]["title"]].include?({ "xmlid" => document["data"]["xmlid"], "token_count" => document["data"]["token_count"] })
        # metadata["Corpus"]["title"][corpus["data"]["title"]] << { "xmlid" => document["data"]["xmlid"], "token_count" => document["data"]["token_count"] }
      # end
    # end
  # end
#   
  # # # load available corpora from server
  # # logger.info  "Loading corpora from server"
  # # cdata = HTTParty.get('http://localhost:7474/db/data/label/Corpus/nodes',
      # # :headers => { 'Content-Type' => 'application/json',
                    # # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
# #   
  # # cdata.each do |corpus|
    # # metadata["Corpus"]["title"][corpus["data"]["title"]] = [{ "xmlid" => "none", "token_count" => corpus["data"]["token_count"]}]
  # # end
#   
  # # load available metadata fields from server
  # logger.info  "Loading metadata from server"
  # data = HTTParty.get('http://localhost:7474/db/data/label/Metadatum/nodes',
      # :headers => { 'Content-Type' => 'application/json',
                    # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
  # # loop through fields
  # data.each do |metadatum|
    # # store fields per group
    # if !metadata.has_key?(metadatum["data"]["group"])
      # metadata[metadatum["data"]["group"]] = {}
    # end
    # if !metadata[metadatum["data"]["group"]].has_key?(metadatum["data"]["key"])
      # metadata[metadatum["data"]["group"]][metadatum["data"]["key"]] = {}
    # end
    # # load field values from server
    # logger.info  "Loading field values and documents from server (label: "+metadatum["data"]["label"]+")"
    # offset = 0
    # number = 1000
    # done = 0
#     
    # while done == 0 do
      # values = HTTParty.get('http://localhost:7474/whitelab/search/metadata/'+metadatum["data"]["label"]+'/values', timeout: NEO4J_TIMEOUT_SECONDS,
        # :query => { "number" => number, 
                   # "offset" => offset,
                   # "sort" => "value", 
                   # "order" => "asc",
                   # "count" => false
                 # },
        # :headers => { 'Content-Type' => 'application/json',
                      # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )["values"]
      # values.each do |value|
        # if !metadata[metadatum["data"]["group"]][metadatum["data"]["key"]].has_key?(value["value"])
          # metadata[metadatum["data"]["group"]][metadatum["data"]["key"]][value["value"]] = []
#           
#           
          # vdata = HTTParty.get('http://localhost:7474/db/data/index/relationship/HAS_METADATUM/value/'+URI.escape(value["value"]),
            # :headers => { 'Content-Type' => 'application/json',
                          # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
#           
          # vdata.each do |v|
            # if v["end"].eql?(metadatum["self"])
              # document = HTTParty.get(v["start"],
                # :headers => { 'Content-Type' => 'application/json',
                              # 'Authorization' => 'Basic '+Base64.encode64(NEO4J_USER+':'+NEO4J_PW) } )
              # metadata[metadatum["data"]["group"]][metadatum["data"]["key"]][value["value"]] << { "xmlid" => document["data"]["xmlid"], "token_count" => document["data"]["token_count"] }
            # end
          # end
        # end
      # end
      # if values.length < number
        # done = 1
      # end
      # offset += number
    # end
  # end
  # # save all data to configuration file
  # logger.info  "Writing metadata coverage to configuration file"
  # File.open(coverage_config, 'w') { |f| YAML.dump({ "coverage" => metadata }, f) }
# end
