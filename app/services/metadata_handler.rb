require 'singleton'
require 'set'

# The MetadataHandler class handles all document metadata
class MetadataHandler
  include Singleton
  include DataFormatHelper
  
  def initialize
    @logger = Logger.new STDOUT
    @logger.info "Initializing metadata handler..."
    @whitelab = WhitelabBackend.instance
    config = Rails.configuration.x
    @format = config.metadata_file_format
    @total_word_count = config.total_token_count
    backend = @whitelab.get_backend_type
    rroot = Rails.root
    generate_metadata_files(backend) if !File.exists?(documents_file) || !File.exists?(metadata_file)
    @documents = read_file(documents_file)
    @metadata = read_file(metadata_file)
    @fields = @documents["fields"]
    @doc_ids = @documents["document_ids"]
    @token_counts = @documents["token_counts"]
    @limit = @doc_ids.size - 1
    set_total_word_count if @total_word_count <= 0
    @logger.info "Metadata handler initialized."
  end
  
  def docpid_to_id(docpid)
    return "id", @metadata["Metadata_id"]["values"][@fields["Metadata_id"][@doc_ids.index(docpid)]] if @fields.has_key?("Metadata_id")
    return "fromInputFile", @metadata["Metadata_fromInputFile"]["values"][@fields["Metadata_fromInputFile"][@doc_ids.index(docpid)]]
  end
  
  # Filter document list
  # return_counts = 0: returns document indices in array
  # return_counts = 1: returns token counts in array
  def filter_documents(filter_str, return_indices = true)
    if !filter_str || filter_str.eql?("")
      return (0..@limit).to_a if return_indices
      return @token_counts
    end
    docs = []
    filter_to_hash(filter_str).each do |group, keys|
      keys.each do |key, mdata|
        metadatum = @metadata["#{group}_#{key}"]
        mdata.each do |set, values|
          if values.any?
            set_matches = get_documents_matching_values(metadatum, values, set.eql?(:negative))
            docs = docs.length > 0 ? docs & set_matches : set_matches
          end
        end
      end
    end
    return docs if return_indices
    return docs.map{|index| @token_counts[index] }
  end
  
  def get_document_id(index)
    return @doc_ids[index]
  end
  
  def get_document_token_count(id)
    return @token_counts[@doc_ids.index(id)]
  end
  
  # Get documents matching metadatum grouped by option value
  def get_filtered_group_composition(option, filter)
    no_filter = !filter || filter.eql?("")
    group, key = get_group_and_key_from_label(option)
    labels = get_labels_from_group_and_key(group, key).select{|label| @fields.has_key?(label) }
    return [] unless labels.any?
    return filter_documents(filter).group_by{|i| labels.map{|label| @metadata[label]['values'][@fields[label][i]] }.select{|value| !value.nil? && !value.eql?('Unknown')}.join(",") }.map{|value,doc_indices| { option => value, 'hit_count' => doc_indices.map{|d| @token_counts[d] }.reduce(:+), 'document_count' => doc_indices.size } }
    
    
  end
  
  def get_filtered_word_count(filter)
    return filter_documents(filter, false).sum
  end
  
  def get_group_and_key_from_label(label)
    group = label.split('_')[0]
    key = label.sub(/#{group}_/,'')
    group = group.eql?(key) ? 'Metadata' : group
    return group, key
  end
  
  def get_group_options(view, namespace)
    groups = {}
    if view == 8
      groups[I18n.t(:"data_labels.keys.hit")] = []
      groups[I18n.t(:"data_labels.keys.left")] = []
      groups[I18n.t(:"data_labels.keys.right")] = []
      ['hit','wordleft','wordright'].each do |position|
        translation = I18n.t(:"data_labels.keys.#{position.sub('word','')}")
        ['word','lemma','pos','phonetic'].each do |annotation|
          groups[translation] << ["#{translation} - #{I18n.t(:"data_labels.keys.#{annotation}")}", position+':'+annotation]
        end
        groups[translation] << ["#{translation} - #{I18n.t(:"data_labels.keys.context")} (#{I18n.t(:"page_titles.keys.advanced")})", 'context'] if position.eql?('hit')
      end
    end
    
    if ENABLE_METADATA_FILTERING
      get_metadata_group_options({}, namespace).sort_by {|k, v| [k, v] }.each do |group, data|
        group = I18n.translate(:"#{group}").capitalize
        if !groups.has_key?(group)
          groups[group] = []
        end
        data.each do |arr|
          field = I18n.translate(:"#{arr[0]}")
          groups[group] << [field, arr[1]]
        end
        groups[group].sort!
      end
    end
    return groups
  end
  
  def get_hoverable_metadata
    return @metadata.keys.select{|mlabel| @metadata[mlabel]['hoverable'].eql?('true') }
  end
  
  def get_labels_from_group_and_key(group, key)
    return @metadata.keys.select{|mlabel| @metadata[mlabel]['group'].eql?(group) && @metadata[mlabel]['key'].eql?(key) }
  end
  
  # Load paginated list of metadata in index
  def get_metadata(number, offset, sort, order)
    fields = @metadata.values.select{|data| !data['key'].include?("\.") }
    total = fields.size
    fields = order.eql?("desc") ? fields.sort_by{|x| x[sort] }.reverse : fields.sort_by{|x| x[sort] }
    return { 'total' => total, 'metadata' => fields[offset..offset+number] }
  end
  
  def get_metadatum(group, key)
    group = group.eql?(key) ? 'Metadata' : group
    label = group.eql?('Metadata') ? key : "#{group}_#{key}"
    matches = @metadata ? @metadata.values.select{|data| data['group'].eql?(group) && data['key'].eql?(key) } : [{ 'group' => group, 'key' => key, 'label' => label }]
    return matches.size == 1 ? matches[0] : matches
  end
  
  def get_metadatum_by_label(label)
    group, key = label.split('_', 2)
    group = group.eql?(key) ? 'Metadata' : group
    matches = @metadata ? @metadata.values.select{|data| data['label'].eql?(label) } : [{ 'group' => group, 'key' => key, 'label' => label }]
    return matches.size == 1 ? matches[0] : matches
  end
  
  def get_metadatum_values(metadatum, filtered_total)
    return metadatum['values'] unless metadatum.is_a?(Array)
    return metadatum[0]['values'] unless metadatum.size > 1
    total_size = 0
    values = metadatum.map{|m| m['values']}.flatten.uniq
    metadatum.each do |m|
      (m['values'] - ["Unknown"]).each do |v|
        total_size += get_filtered_word_count("(#{m['group']}_#{m['key']}=\"#{v}\")")
      end
    end
    if total_size >= filtered_total
      values -= ["Unknown"]
    end
    return values
  end
  
  def get_total_word_count
    return @total_word_count
  end
  
  def load_corpora
    group, key = get_group_and_key_from_label(CORPUS_TITLE_FIELD)
    return @metadata ? @metadata[CORPUS_TITLE_FIELD]['values'] : load_values_from_server(0, 0, "label", "asc", group, key)
  end
  
  def load_values(metadatum)
    data = @metadata["#{group}_#{key}"]
    return data['values'], data['value_count']
  end
  
  def metadata
    return @metadata
  end
  
  def reformat_metadatum_values(metadatum)
    data = []
    metadatum['values'].each_with_index do |value, i|
      docs = get_documents_matching_values(metadatum, [i])
      group, key = get_group_and_key_from_label(CORPUS_TITLE_FIELD)
      corpus_metadatum = get_metadatum(group, key)
      data << { 'value' => value, 'document_count' => docs.size, 'corpus_counts' => { 'corpora' => corpus_metadatum['values'], 'counts' => (0..corpus_metadatum['value_count']-1).to_a.map{|j| (get_documents_matching_values(corpus_metadatum, [j]) & docs).size } } }
    end
    return data
  end
  
  def load_values_from_server(number, offset, sort, order, group, key)
    data = []
    metadatum = get_metadatum(group, key)
    @whitelab.get_metadatum_values_by_label(number, 0, "label", "asc", metadatum['label']).each do |value|
      value = value.kind_of?(Hash) ? value['value'] : value
      data << value
    end
    data
  end
  
  def save_metadata
    write_file(metadata_file, @metadata)
  end
  
  def update_metadatum(metadatum, updates)
    if @whitelab.respond_to?(:update_metadatum)
      @whitelab.update_metadatum(metadatum, updates)
    else
      updates.each do |k,v|
        metadatum[k] = v
      end
      save_metadata
    end
  end
  
  private
  
  def documents_file
    return Rails.root.join("config", "metadata_#{@whitelab.get_backend_type}", "documents.#{@format}")
  end
  
  def filter_to_hash(filter)
    filters = {}
    filter[1, filter.length - 2].split(')AND(').each do |filter_part|
      label, unstripped_value = filter_part.split(/\!*[=\:]/)
      unless unstripped_value.blank?
        stripped_value = strip_value(unstripped_value)
        group, key = get_group_and_key_from_label(label)
        metadatum = get_metadatum(group, key)
        metadatum = metadatum.is_a?(Array) ? metadatum.select{|m| m['values'].include?(stripped_value) }[0] : metadatum
        has_group = filters.has_key?(metadatum['group'])
        group, key = get_group_and_key_from_label(metadatum['label'])
        matches = has_group && filters[group].has_key?(key) ? filters[group][key] : { :positive => [], :negative => [] }
        matches[filter_part.eql?("#{label}!=#{unstripped_value}") ? :negative : :positive] << value_to_index("#{metadatum['label']}", stripped_value)
        filters[group] = {} unless has_group
        filters[group][key] = matches
      end
    end
    return filters
  end
  
  def get_corpus_division(doc_indices, corpora)
    sizes = {}
    corpora.each do |corpus, docs|
      sizes[corpus] = (doc_indices & docs).size
    end
    return sizes
  end
  
  def generate_metadata_files(backend)
    @logger.info "Generating metadata files..."
    output_dir = Rails.root.join("config", "metadata_#{backend}")
    FileUtils.mkpath(output_dir) unless File.exists?(output_dir)
    documents = {
      'document_ids' => [],
      'token_counts' => [],
      'fields' => {}
    }
    corpora = ENABLE_METADATA_FILTERING ? @whitelab.get_metadatum_values_by_label(500, 0, "label", "asc", CORPUS_TITLE_FIELD) : []
    
    offset = 0
    number = 2500
    unfiltered = true
    filters = ENABLE_METADATA_FILTERING ? corpora.map{|corpus| "#{CORPUS_TITLE_FIELD}:#{corpus}" } : ['[]']
    f = 0
    mfile = metadata_file
    metadata = File.exists?(mfile) ? JSON.parse(File.read(mfile)) : {}
    skip = ['Metadata_lengthInTokens','Metadata_metadataCid','Metadata_version']
    @whitelab.get_metadata_from_server(0, 0, nil, nil).each do |metadatum|
      if metadatum[:group].eql?(metadatum[:key])
        metadatum[:group] = metadatum[:key].eql?('Id') ? 'Language' : 'Metadata'
        metadatum[:label] = "#{metadatum[:group]}_#{metadatum[:key]}"
      end
      unless skip.include?(metadatum[:label]) || metadatum[:label].include?('.')
        metadatum[:values] = []
        metadatum[:value_count] = 0
        metadatum[:file] = Rails.root.join("config", "metadata_#{backend}", "#{metadatum[:label]}.txt")
        File.delete(metadatum[:file]) if File.exists?(metadatum[:file])
        corpora.each do |corpus|
          metadatum[:"document_count_#{corpus}"] = 0
        end
        metadata[metadatum[:label]] = metadatum
      end
    end
    done = false
    while !done do
      data = unfiltered ? @whitelab.get_document_list(offset, number) : @whitelab.get_filtered_document_list(filters[f],offset, number)
      if unfiltered && data.has_key?('error')
        unfiltered = false
      elsif !unfiltered && data['docs'].size == 0 && f < filters.size - 1
        f += 1
        offset = 0
      else
        documents['document_ids'].concat(data['docs'].map{|doc| doc['docPid'] })
        documents['token_counts'].concat(data['docs'].map{|doc| doc['docInfo']['lengthInTokens'] })
        metadata.keys.each do |label|
          unless skip.include?(label)
            metadatum = metadata[label]
            fieldLabel = label.start_with?('Metadata') ? metadatum[:key] : label
            corpora.each do |corpus|
              metadatum[:"document_count_#{corpus}"] += data['docs'].select{|doc| doc['docInfo'][CORPUS_TITLE_FIELD].eql?(corpus) }.size
            end
            File.open(metadatum[:file], "a") do |file|
              data['docs'].each do |doc|
                if doc['docInfo'].has_key?(fieldLabel) && !doc['docInfo'][fieldLabel].blank? && !doc['docInfo'][fieldLabel].nil?
                  file.puts "#{doc['docInfo'][fieldLabel].gsub(/\n/,'\n')}"
                else
                  file.puts "Unknown"
                end
              end
            end
          end
        end
        if (data.has_key?('summary') && (!data['summary'].has_key?('windowHasNext') || !data['summary']['windowHasNext'])) || (!data.has_key?('summary') && data['docs'].size < number)
          if !unfiltered && f < filters.size - 1
            f += 1
            offset = 0
          else
            done = true
          end
        else
          offset += number
        end
      end
    end
    metadata.keys.each do |k|
      unless skip.include?(k)
        values = File.readlines(metadata[k][:file]).map(&:chomp)
        metadata[k][:values] = values.uniq
        s = (metadata[k][:values] - ['Unknown']).size
        metadata[k][:value_count] = s
        if s == values.size
          values = (0..s-1).to_a
        elsif s < 2
          values = Array.new(values.size, 0)
        else
          values.map!{|value| metadata[k][:values].index(value) }
        end
        documents['fields'][metadata[k][:label]] = values
        File.delete(metadata[k][:file])
        metadata[k].except!(:file)
        write_file(mfile, metadata)
      end
    end
    write_file(documents_file, documents)
    @logger.info "Finished generating metadata files."
  end
  
  def get_documents_matching_values(metadatum, values, inverted = false)
    return [] if !values.any?
    if metadatum.is_a?(Array)
      docs = []
      @doc_ids.each_index.select do |i|
        doc_values = metadatum.map{|m| @fields["#{m['label']}"][i] }
        if inverted
          (values & doc_values).size == 0
        else
          (values & doc_values).size > 0
        end
      end
    else
      arr = @fields["#{metadatum['label']}"]
      docs =  arr.each_index.select do |i|
        if inverted
          !values.include?(arr[i])
        else
          values.include?(arr[i])
        end
      end
      return docs
    end
  end
  
  # Load options for grouping by metadatum
  def get_metadata_group_options(groups, namespace)
    @metadata.values.each do |data|
      key = data['key']
      unless key.include?("\.") || (namespace.eql?('explore') && data.has_key?('explorable') && data['explorable'].eql?('false')) || 
        (namespace.eql?('search') && data.has_key?('searchable') && data['searchable'].eql?('false'))
        tr_group = group_translation_key(data['group'])
        groups[tr_group] = [] unless groups.has_key?(tr_group)
        kt = key_translation_key(key)
        label = "#{data['group']}_#{data['key']}"
        groups[tr_group] << [kt, label] unless groups[tr_group].include?([kt, label])
        # groups[tr_group] << [key_translation_key(key), data['label']]
      end
    end
    groups
  end
  
  def metadata_file
    return Rails.root.join("config", "metadata_#{@whitelab.get_backend_type}", "metadata.#{@format}")
  end
  
  def read_file(file, key = nil)
    data = @format.eql?(:json) ? Yajl::Parser.parse(File.read(file)) : YAML.load_file(file)
    return key ? data[key] : data
  end
  
  def set_total_word_count
    @total_word_count = @token_counts.sum
    Rails.configuration.x.total_token_count = @total_word_count
  end
  
  # Strip quotes from metadatum value
  def strip_value(value)
    return value if value.nil?
    return value.chomp('"').reverse.chomp('"').reverse
  end
  
  def value_to_index(label, value)
    return value if value.nil?
    return @metadata["#{label}"]["values"].index(value)
  end
  
  def write_file(outfile, data)
    dir = File.dirname(outfile)
    FileUtils.mkpath(dir) unless File.exists?(dir)
    File.open(outfile, 'w', external_encoding: 'ASCII-8BIT') do |file|
      @format.eql?(:yml) ? YAML.dump(data, file) : file.write(data.to_json)
    end
  end
  
end