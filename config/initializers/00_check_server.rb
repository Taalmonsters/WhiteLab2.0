backend = WhitelabBackend.instance
logger = Logger.new STDOUT
logger.formatter = Logger::Formatter.new

logger.info "Initializing Whitelab version #{Rails.application.config.whitelab_version}"
logger.info "Using backend '#{backend.get_backend_type}' version #{backend.version}"

data = {
  :url => backend.get_backend_type.eql?('neo4j') ? "#{backend.backend_url}db/data/" : backend.backend_url,
  :headers => backend.headers
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
