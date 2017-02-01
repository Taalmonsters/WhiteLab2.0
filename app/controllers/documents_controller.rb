# Controller for retrieval of document data.
class DocumentsController < ApplicationController
  before_action :set_limits
  
  # Load document audio
  def audio
    if @document
      format = params[:format] || 'mp3'
      audio_file = @document.audio_file(format)
      file_begin = 0
      file_size = File.size(audio_file) 
      file_end = file_size - 1
      req_headers = request.headers
      resp_header = response.header
    
      if !req_headers["Range"]
        status_code = "200 OK"
      else
        status_code = "206 Partial Content"
        match = req_headers['range'].match(/bytes=(\d+)-(\d*)/)
        if match
          file_begin = match[1]
          file_end = file_begin if match[2] && !match[2].empty?
        end
        resp_header["Content-Range"] = "bytes #{file_begin}-#{file_end}/#{file_size}"
      end
      resp_header["Content-Length"] = (file_end.to_i - file_begin.to_i + 1).to_s
    
      resp_header["Cache-Control"] = "public, must-revalidate, max-age=0"
      resp_header["Pragma"] = "no-cache"
      resp_header["Accept-Ranges"]=  "bytes"
      resp_header["Content-Transfer-Encoding"] = "binary"
      send_file(audio_file, 
        :filename => "#{@document.xmlid}.#{format}",
        :type => "audio/#{format}", 
        :disposition => "inline",
        :status => status_code,
        :stream =>  'true',
        :buffer_size  =>  4096)
    end
  end
  
  # Load document content
  def content
    @tab = 'content'
    respond_to do |format|
      if @document
        format.js { render '/documents/content' }
        format.json { render json: @document.content }
        format.xml { render xml: @document.xml_content }
      else
        @msg = {}
        @msg[:error] = "Document '#{params[:xmlid]}' not found"
        format.js { render '/layouts/error' }
        format.json { render json: @msg }
        format.xml { render xml: @msg }
      end
    end
  end
  
  # Load document metadata
  def metadata
    @tab = 'metadata'
    respond_to do |format|
      if @document
        metadata = @document.metadata
        format.js { render '/documents/metadata' }
        format.json { render json: metadata }
        format.xml { render xml: metadata }
      else
        @msg = {}
        @msg[:error] = "Document '#{params[:xmlid]}' not found"
        format.js { render '/layouts/error' }
        format.json { render json: @msg }
        format.xml { render xml: @msg }
      end
    end
  end
  
  # Load distribution of PoS tags in document
  def pos_distribution
    respond_to do |format|
      if @document
        pos_distribution = @document.pos_distribution
        format.json { render json: pos_distribution }
        format.xml { render xml: pos_distribution }
      else
        flash[:error] = "Document '#{params[:xmlid]}' not found"
        format.json { render json: flash }
        format.xml { render xml: flash }
      end
    end
  end
  
  # Load document statistics
  def statistics
    @tab = 'statistics'
    respond_to do |format|
      if @document
        statistics = @document.statistics
        format.js { render '/documents/statistics' }
        format.json { render json: statistics }
        format.xml { render xml: statistics }
      else
        @msg = {}
        @msg[:error] = "Document '#{params[:xmlid]}' not found"
        format.js { render '/layouts/error' }
        format.json { render json: @msg }
        format.xml { render xml: @msg }
      end
    end
  end
  
  # Load vocabulary growth for document
  def vocabulary_growth
    respond_to do |format|
      if @document
        growth = @document.growth
        format.json { render json: growth }
        format.xml { render xml: growth }
      else
        flash[:error] = "Document '#{params[:xmlid]}' not found"
        format.json { render json: flash }
        format.xml { render xml: flash }
      end
    end
  end
  
  protected

  # Get offset and number for selecting document content partitions from the GET parameters
  def set_limits
    @offset = !params[:offset].blank? ? params[:offset].to_i : 0
    @number = !params[:number].blank? ? params[:number].to_i : 50
  end
end