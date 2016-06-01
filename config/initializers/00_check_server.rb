backend = WhitelabBackend.instance
logger = Logger.new STDOUT
logger.formatter = Logger::Formatter.new

logger.info "Using backend '"+backend.get_backend_type+"'"

data = {
  :url => backend.get_backend_type.eql?('neo4j') ? backend.get_url+'db/data/' : backend.get_url,
  :headers => backend.get_query_headers
}

if backend.get_backend_type.eql?('blacklab')
  data[:query] = {
    "outputformat" => "json"
  }
end

logger.info "Checking server connection..."
check = backend.execute_query(data)
if (backend.get_backend_type.eql?('neo4j') && check.has_key?("neo4j_version")) || (backend.get_backend_type.eql?('blacklab') && check.has_key?("status") && check["status"].eql?("available"))
  logger.info "Server is up."
  metadata_handler = MetadataHandler.instance
else
  logger.error "Failed to connect to server!"
end
