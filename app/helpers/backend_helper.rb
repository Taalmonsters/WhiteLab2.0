require 'net/http'
require 'uri'

# Main backend helper module.
module BackendHelper
  
  def execute_query(data)
    resp = nil
    if data.has_key?(:method) && data[:method].eql?('post')
      if data.has_key?(:query)
        resp = post_query(data)
      else
        resp = post_headers(data)
      end
    else
      if data.has_key?(:query)
        resp = get_query(data)
      else
        resp = get_headers(data)
      end
    end
    if WhitelabBackend.instance.get_backend_type.eql?('neo4j')
      return resp.parsed_response
    else
      return resp
    end
  end
  
  def get_headers(data)
    HTTParty.get(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :headers => data[:headers]
    )
  end
  
  def get_number(query, docpid, number)
    n = query.number
    if !number.blank?
      n = number
    elsif !docpid.blank?
      n = 50
    end
    return n
  end
  
  def get_offset(query, docpid, offset)
    o = query.offset
    if !offset.blank?
      o = offset
    elsif !docpid.blank?
      o = 0
    end
    return o
  end
  
  def get_query(data)
    HTTParty.get(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :query => data[:query],
      :headers => data[:headers]
    )
  end
  
  def get_response_stream(data, target)
    uri = URI(data[:url])
    uri.query = URI.encode_www_form(data[:query])
    
    request = nil
    if data.has_key?(:method) && data[:method].eql?('post')
      request = Net::HTTP::Post.new(uri.path)
    else
      request = Net::HTTP::Get.new(uri.path)
    end
    @@HEADERS.each do |key, value|
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
  
  def get_view(query, docpid, view)
    v = query.view
    if !view.blank?
      v = view
    elsif !docpid.blank?
      v = 1
    end
    return v
  end
  
  def get_within(query, default)
    w = default
    if query.has_attribute?(:within) && !query.within.blank?
      w = query.within
    end
    return w
  end
  
  def post_headers(data)
    HTTParty.post(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :headers => data[:headers]
    )
  end
  
  def post_query(data)
    HTTParty.post(data[:url], timeout: BACKEND_TIMEOUT_SECONDS,
      :query => data[:query],
      :headers => data[:headers]
    )
  end
  
end