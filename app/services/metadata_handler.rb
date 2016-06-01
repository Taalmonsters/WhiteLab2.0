require 'singleton'

# The MetadataHandler class handles all document metadata
class MetadataHandler
  include Singleton
  include DataFormatHelper
  
  def initialize
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
    set_total_word_count if @total_word_count == 0
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
        metadatum = {'group' => group, 'key' => key}
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
  
  def get_document(id)
    return @documents[id]
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
    label = "#{group}_#{key}"
    list = @fields[label]
    field_values = @metadata[label]['values']
    if no_filter
      return list.each_index.group_by{|i| list[i] }.map{|value,doc_indices| { option => field_values[value], 'hit_count' => doc_indices.map{|d| @token_counts[d] }.reduce(:+), 'document_count' => doc_indices.size } }
    else
      filtered_doc_indices = filter_documents(filter)
      grouped = filtered_doc_indices.group_by{|i| list[i] }
      return grouped.map{|value,doc_indices| { option => field_values[value], 'hit_count' => doc_indices.map{|d| @token_counts[d] }.reduce(:+), 'document_count' => doc_indices.size } }
    end
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
      groups['hit'] = []
      groups['left'] = []
      groups['right'] = []
      ['hit','left','right'].each do |position|
        ['text','lemma','pos','phonetic'].each do |annotation|
          groups[position] << [annotation, position+'_'+annotation]
        end
      end
    end
    
    get_metadata_group_options({}, namespace).sort_by {|k, v| [k, v] }.each do |group, data|
      group = I18n.translate(:"#{group}").capitalize
      if !groups.has_key?(group)
        groups[group] = []
      end
      data.each do |arr|
        field = I18n.translate(:"#{arr[0]}")
        groups[group] << [field, arr[1]]
      end
    end
    return groups
  end
  
  # Load paginated list of metadata in index
  def get_metadata(number, offset, sort, order)
    fields = @metadata.values.select{|data| !data['key'].include?("\.") }
    return { 'total' => fields.size, 'metadata' => fields[offset..offset+number] }
  end
  
  def get_metadatum(group, key)
    group = group.eql?(key) ? 'Metadata' : group
    return @metadata.values.select{|data| data['group'].eql?(group) && data['key'].eql?(key) }[0]
  end
  
  def get_total_word_count
    return @total_word_count
  end
  
  def load_corpora
    return @metadata ? @metadata['Corpus_title']['values'] : load_values_from_server(0, 0, "label", "asc", 'Corpus', 'title')
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
      corpus_metadatum = get_metadatum('Corpus', 'title')
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
      label, unstripped_value = filter_part.split(/\!*=/)
      group, key = get_group_and_key_from_label(label)
      has_group = filters.has_key?(group)
      matches = has_group && filters[group].has_key?(key) ? filters[group][key] : { :positive => [], :negative => [] }
      matches[filter_part.eql?("#{label}!=#{unstripped_value}") ? :negative : :positive] << value_to_index(label, strip_value(unstripped_value))
      filters[group] = {} unless has_group
      filters[group][key] = matches
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
    Rails.logger.info "Generating metadata files..."
    documents = []
    counts = []
    fields = {}
    metadata_values = {}
    corpora = {}
    data = @whitelab.get_document_list(load_corpora)
    data.keys.each_with_index do |doc_id, i|
      doc_data = data[doc_id]
      documents << doc_id
      counts << doc_data['token_count']
      corpus = doc_data['corpus']
      corpora[corpus] = [] unless corpora.has_key?(corpus)
      corpora[corpus] << i
    end
    doc_size = documents.size
    @whitelab.get_metadata_from_server(0, 0, nil, nil).each do |metadatum|
      label = metadatum[:label]
      group, key = get_group_and_key_from_label(label)
      doc_values = Array.new(doc_size)
      values = []
      done = []
      @whitelab.get_metadatum_values_by_label(doc_size, 0, "label", "asc", label).each do |value|
        unless value.blank?
          i = values.size
          values << value
          @whitelab.get_document_id_list("#{label}=\"#{value}\"").each do |doc_id|
            doc_index = documents.index(doc_id)
            doc_values[doc_index] = i
            done < doc_index
          end
        end
      end
      dsize = done.size
      if dsize > 0
        sizes = get_corpus_division(done, corpora)
        if dsize < doc_size
          i = values.size
          values << 'No value'
          ((0..(doc_size-1)).to_a - done).each do |doc_index|
            doc_values[doc_index] = i
          end
        end
        fields["#{label}"] = doc_values
        field = {
          'group' => group,
          'key' => key,
          'label' => label,
          'values' => values,
          'value_count' => (values - ['No value']).size
        }
        get_corpus_division(done, corpora).each do |corpus, size|
          field["document_count_#{corpus}"] = size
        end
        metadata_values[label] = field
      end
    end
    rroot = Rails.root
    write_file(documents_file, { "document_ids" => documents, "token_counts" => counts, "fields" => fields })
    write_file(metadata_file, metadata_values)
    Rails.logger.info "Finished generating metadata files."
  end
  
  def get_documents_matching_values(metadatum, values, inverted = false)
    return [] if !values.any?
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
  
  # Load options for grouping by metadatum
  def get_metadata_group_options(groups, namespace)
    @metadata.values.each do |data|
      key = data['key']
      unless key.include?("\.") || (namespace.eql?('explore') && data.has_key?('explorable') && data['explorable'].eql?('false')) || 
        (namespace.eql?('search') && data.has_key?('searchable') && data['searchable'].eql?('false'))
        tr_group = group_translation_key(data['group'])
        groups[tr_group] = [] unless groups.has_key?(tr_group)
        groups[tr_group] << [key_translation_key(key), data['label']]
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
    value.chomp('"').reverse.chomp('"').reverse
  end
  
  def value_to_index(label, value)
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