require 'net/http'
require 'uri'
require 'cgi'

# Main backend helper module.
module BackendHelper

  # Get the base URL for querying the backend from the application configuration
  def backend_url
    Rails.configuration.x.database_url
  end

  # Get the URL where the CQL definition is hosted. This is added to the CQL info dialog on the Expert Search page
  def cql_info_url
    return "http://inl.github.io/BlackLab/corpus-query-language.html"
  end

  # If gap values are enabled, the 'Import TSV' buttons in Expert Search and Explore N-grams are active.
  # If gap values are disabled, the 'Import TSV' buttons show an alert explaining the functionality, but do not allow file upload.
  def gap_values_enabled
    return false
  end

  # Return the default headers to be sent to the backend with each request.
  def headers
    return { 'Content-Type' => 'application/json' }
  end

  # Execute a search on the backend
  def search(query, url)
    Rails.logger.debug "SEARCH ON BACKEND"
    data = { 
      :query => reformat_query_attributes(query),
      :url => url
    }
    return finish_query(query, get_query(data))
  end

  # Execute a query on the backend
  def execute_query(data)
    has_query = data.has_key?(:query)
    unless data.has_key?(:method) && data[:method].eql?('post')
      return has_query ? get_query(data) : get_headers(data).parsed_response
    end
    return has_query ? post_query(data).parsed_response : get_headers(data).parsed_response
  end

  # Send a request with only headers (no query) to the backend using GET
  def get_headers(data)
    HTTParty.get(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :headers => headers
    )
  end

  # Get the value for the number parameter for paginated queries
  def get_number(query, docpid, number)
    n = query.number
    if !number.blank?
      n = number
    elsif !docpid.blank?
      n = 50
    end
    return n
  end

  # Get the value for the offset parameter for paginated queries
  def get_offset(query, docpid, offset)
    o = query.offset
    if !offset.blank?
      o = offset
    elsif !docpid.blank?
      o = 0
    end
    return o
  end

  # Send a request with both headers and a query to the backend using GET
  def get_query(data)
    Rails.logger.debug "GETTING QUERY WITH HEADERS (timeout = #{BACKEND_TIMEOUT_SECONDS} s):"
    Rails.logger.debug headers
    Rails.logger.debug data[:query]
    uri = URI(data[:url])
    uri.query = URI.encode_www_form(data[:query])
    resp = ''
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      resp = http.request request
    end
    return JSON.parse(resp.body.gsub(/\r/,''))
  end

  # Receive the backend response as a stream
  def get_response_stream(data, target)
    uri = URI(data[:url])
    uri.query = URI.encode_www_form(data[:query])
    
    request = nil
    if data.has_key?(:method) && data[:method].eql?('post')
      request = Net::HTTP::Post.new(uri.path)
    else
      request = Net::HTTP::Get.new(uri.path)
    end
    headers.each do |key, value|
      request.add_field(key, value)
    end

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request request do |response|
        open target, 'w' do |io|
          response.read_body do |chunk|
            io.write chunk
          end
        end
      end
    end
  end

  # Retrieve result counts for a query from the backend
  def get_search_result_counts_for_query(query, docpid, view, number, offset)
    count_obj = {
      :query => query,
      :view => get_view(query, docpid, view),
      :offset => get_offset(query, docpid, offset),
      :number => get_number(query, docpid, number),
      :within => get_within(query, 'document')
    }
    vview = count_obj[:view]
    if [1,2].include?(vview)
      count_results(vview == 1 ? "hits" : "docs", count_obj)
    elsif [8,16].include?(vview)
      count_grouped_results(vview == 8 ? "hits" : "docs", count_obj)
    end
  end

  # Get the value for the view parameter for a query
  def get_view(query, docpid, view)
    v = query.view
    if !view.blank?
      v = view
    elsif !docpid.blank?
      v = 1
    end
    return v
  end

  # Get the value for the within parameter for a query
  def get_within(query, default)
    w = default
    if query.has_attribute?(:within) && !query.within.blank?
      w = query.within
    end
    return w
  end

  # Send a request with only headers (no query) to the backend using POST
  def post_headers(data)
    HTTParty.post(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :headers => headers
    )
  end

  # Send a request with both headers and a query to the backend using POST
  def post_query(data)
    HTTParty.post(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :query => data[:query],
      :headers => headers
    )
  end

  # Default method to get a list of PoS head tags
  def get_pos_heads(number, offset, sort, order)
    data = ['ADJ', 'BW', 'LET', 'LID', 'N', 'SPEC', 'TW', 'TSW', 'VG', 'VNW', 'VZ', 'WW']
    ph = {
      "total" => data.size,
      "number" => number,
      "offset" => offset,
      "sort" => sort,
      "order" => order,
      "pos_heads" => []
    }
    data.each do |group|
      ph["pos_heads"] << {
        "label" => group,
        "token_count" => 0
      }
    end
    ph
  end
  
end