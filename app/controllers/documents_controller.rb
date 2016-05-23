# Controller for retrieval of document data.
class DocumentsController < ApplicationController
  include DataFormatHelper
  
  before_action :set_xmlid
  
  # Load document audio
  def audio
    if @xmlid && params[:format]
      audio_file_path = "#{Rails.configuration.x.audio_dir+"/"+params[:format]+"/"+@xmlid+"."+params[:format]}"
      file_begin = 0
      file_size = File.size(audio_file_path) 
      file_end = file_size - 1
    
      if !request.headers["Range"]
        status_code = "200 OK"
      else
        status_code = "206 Partial Content"
        
        match = request.headers['range'].match(/bytes=(\d+)-(\d*)/)
        if match
          file_begin = match[1]
          file_end = match[1] if match[2] && !match[2].empty?
        end
        response.header["Content-Range"] = "bytes " + file_begin.to_s + "-" + file_end.to_s + "/" + file_size.to_s
      end
      response.header["Content-Length"] = (file_end.to_i - file_begin.to_i + 1).to_s
    
      response.header["Cache-Control"] = "public, must-revalidate, max-age=0"
      response.header["Pragma"] = "no-cache"
      response.header["Accept-Ranges"]=  "bytes"
      response.header["Content-Transfer-Encoding"] = "binary"
      send_file(audio_file_path, 
        :filename => "#{params[:xmlid]+"."+params[:format]}",
        :type => "audio/#{params[:format]}", 
        :disposition => "inline",
        :status => status_code,
        :stream =>  'true',
        :buffer_size  =>  4096)
    end
  end
  
  # Load document content
  def content
    @tab = 'content'
    @offset = 0
    if params[:offset]
      @offset = params[:offset].to_i
    end
    @number = 50
    # @number = @backend.get_backend_type.eql?('blacklab') ? 500 : 50
    # if params[:number]
      # @number = params[:number].to_i
    # end
    patt = nil
    if params[:id]
      patt = SearchQuery.find(params[:id].to_i).patt
    end
    @document = {}
    data = @backend.get_document_content(@xmlid,patt,@offset,@number)
    
    paragraphs = {}
    current_paragraph = 0
    current_sentence = 0
    page_begin_time = nil
    page_end_time = nil
    current_end_time = nil
    data['content'].each do |token|
      if token.has_key?('paragraph_start') && token['paragraph_start'].eql?('true')
        current_paragraph = current_paragraph + 1
        current_sentence = 1
        paragraphs[current_paragraph] = {
          'sentences' => {},
          'paragraph_type' => 'p'
        }
        if token.has_key?('paragraph_type') && !token['paragraph_type'].blank?
          paragraphs[current_paragraph]['paragraph_type'] = token['paragraph_type']
        end
        paragraphs[current_paragraph]['sentences'][current_sentence] = {
          'tokens' => [],
          'sentence_speaker' => nil,
          'begin_time' => token['begin_time'],
          'end_time' => nil
        }
        if !token['begin_time'].eql?('Unknown') && page_begin_time.blank?
          page_begin_time = token['begin_time']
        end
        if token.has_key?('sentence_speaker') && !token['sentence_speaker'].blank?
          paragraphs[current_paragraph]['sentences'][current_sentence]['sentence_speaker'] = token['sentence_speaker']
        end
      elsif token.has_key?('sentence_start') && token['sentence_start'].eql?('true')
        if current_paragraph == 0
          current_paragraph = 1
        end
        if !paragraphs.has_key?(current_paragraph)
          paragraphs[current_paragraph] = {
            'sentences' => {},
            'paragraph_type' => 'p'
          }
        end
        if current_sentence >= 1
          paragraphs[current_paragraph]['sentences'][current_sentence]['end_time'] = current_end_time
        end
        current_sentence = current_sentence + 1
        paragraphs[current_paragraph]['sentences'][current_sentence] = {
          'tokens' => [],
          'sentence_speaker' => nil,
          'begin_time' => token['begin_time'],
          'end_time' => nil
        }
        if !token['begin_time'].eql?('Unknown') && page_begin_time.blank?
          page_begin_time = token['begin_time']
        end
        if token.has_key?('sentence_speaker') && !token['sentence_speaker'].blank?
          paragraphs[current_paragraph]['sentences'][current_sentence]['sentence_speaker'] = token['sentence_speaker']
        end
      end
      if current_paragraph == 0
        current_paragraph = 1
      end
      if !paragraphs.has_key?(current_paragraph)
        paragraphs[current_paragraph] = {
          'sentences' => {},
          'paragraph_type' => 'p'
        }
      end
      if current_sentence == 0
        current_sentence = 1
      end
      if !paragraphs[current_paragraph]['sentences'].has_key?(current_sentence)
        paragraphs[current_paragraph]['sentences'][current_sentence] = {
          'tokens' => [],
          'sentence_speaker' => nil,
          'begin_time' => token['begin_time'],
          'end_time' => nil
        }
      end
      paragraphs[current_paragraph]['sentences'][current_sentence]['tokens'] << token
      paragraphs[current_paragraph]['sentences'][current_sentence]['end_time'] = token['end_time']
      if token.has_key?('end_time') && !token['end_time'].blank? && !token['end_time'].eql?('Unknown')
        current_end_time = token['end_time']
      end
    end
    paragraphs[current_paragraph]['sentences'][current_sentence]['end_time'] = current_end_time
    @document['content'] = { 'paragraphs' => paragraphs, 'audio_file' => data['audio_file'], 'total_sentence_count' => data['total_sentence_count'], 'begin_time' => page_begin_time, 'end_time' => current_end_time }
    
    respond_to do |format|
      format.js do
        render '/documents/content'
      end
    end
  end
  
  # Load vocabulary growth for document
  def vocabulary_growth
    n = 0
    if @backend.get_backend_type.eql?('blacklab')
      n = @backend.get_document_token_count(@xmlid)
    end
    data = @backend.get_document_content(@xmlid,nil,0,n)
    render json: format_for_vocabulary_growth(data['content'])
  end
  
  # Load distribution of PoS tags in document
  def pos_distribution
    @document = {}
    n = 0
    if @backend.get_backend_type.eql?('blacklab')
      n = @backend.get_document_token_count(@xmlid)
    end
    data = @backend.get_document_content(@xmlid,nil,0,n)
    data['content'].each do |token|
      pos_head = token['pos_tag'].split('(')[0]
      if !@document.has_key?(pos_head)
        @document[pos_head] = 0
      end
      @document[pos_head] = @document[pos_head] + 1
    end
    render json: { title: 'Token/POS Distribution', data: @document.sort_by {|k2, v2| v2 }.reverse.map{|k,v| { name: k, y: v} } }
  end
  
  # Load document metadata
  def metadata
    @tab = 'metadata'
    @document = {}
    @document['metadata'] = @backend.get_document_metadata(@xmlid)
    respond_to do |format|
      format.js do
        render '/documents/metadata'
      end
    end
  end
  
  # Load document statistics
  def statistics
    @tab = 'statistics'
    @data = @backend.get_document_statistics(@xmlid)
    respond_to do |format|
      format.js do
        render '/documents/statistics'
      end
    end
  end
  
  protected
  
  # Get current document id from parameters
  def set_xmlid
    if params[:xmlid]
      @xmlid = params[:xmlid]
    end
  end
  
end