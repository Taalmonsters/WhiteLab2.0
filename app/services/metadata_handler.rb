require 'singleton'

# The MetadataHandler class handles all document metadata
class MetadataHandler
  include Singleton
  include DataFormatHelper
  
  def initialize
    @whitelab = WhitelabBackend.instance
    @format = Rails.configuration.x.metadata_file_format
    @total_word_count = Rails.configuration.x.total_token_count
    backend = @whitelab.get_backend_type
    rroot = Rails.root
    documents_file = rroot.join("config", "metadata_#{backend}", "documents.#{@format}")
    generate_documents_file(documents_file) unless File.exists?(documents_file)
    @documents = read_file(documents_file, 'documents')
    metadata_file = rroot.join("config", "metadata_#{backend}.#{@format}")
    generate_metadata_file(metadata_file) unless File.exists?(metadata_file)
    @metadata = read_file(metadata_file, 'metadata')
    set_total_word_count if @total_word_count == 0
  end
  
  def document_ids_to_indices(ids)
    ids.map{|id| @documents.keys.index(id) }
  end
  
  def document_indices_to_ids(indices)
    indices.map{|index| @documents.keys[index] }
  end
  
  def filter_documents(filter_str)
    if !filter_str || filter_str.blank?
      return @documents.keys
    end
    docs = []
    filter_to_hash(filter_str).each do |group, keys|
      keys.each do |key, mdata|
        metadatum = generate_metadatum_object(group, key)
        mdata.each do |set, values|
          if values.any?
            set_matches = get_documents_matching_values(metadatum, values, set.eql?(:negative))
            docs = docs.length == 0 ? set_matches : docs & set_matches
          end
        end
      end
    end
    docs.uniq
  end
  
  def generate_metadatum_object(group, key)
    group_equals_key = group.eql?(key)
    {
      :group => group_equals_key ? 'Metadata' : group,
      :key => key,
      :label => group_equals_key || group.eql?('Metadata') ? key : "#{group}_#{key}"
    }
  end
  
  def get_document(id)
    @documents[id]
  end
  
  def get_document_by_index(index)
    get_document(get_document_id(index))
  end
  
  def get_document_id(index)
    @documents.keys[index]
  end
  
  def get_document_token_count(xmlid)
    @documents[xmlid]['token_count']
  end
  
  # Get documents matching metadatum grouped by option value
  def get_filtered_group_composition(option, filter)
    docs_included = filter_documents(filter)
    set_size = (docs_included.size / 10).round + 1
    threads = []
    docs_with_counts = {}
    docs_included.each_slice(set_size) do |set|
      threads << Thread.new do
        output = {}
        set.each do |doc|
          output[doc] = get_document_token_count(doc)
        end
        Thread.current[:output] = output
      end
    end
    threads.each do |thread|
      thread.join
      docs_with_counts.merge!(thread[:output])
    end
    docs_included = []
    first_part = option.split(/\!*=/)[0]
    group = "Metadata"
    key = first_part
    if first_part.include?("_")
      group = first_part.split('_')[0]
      key = first_part.sub(group+'_','')
    end
    result = {}
    read_file(metadatum_file({ :group => group, :key => key }), 'values').each do |value, doc_indices|
      doc_ids = docs_with_counts.keys & doc_indices.map{|doc_index| @documents.keys[doc_index] }
      docs_included += doc_ids
      result[value] = { option => value, 'hit_count' => docs_with_counts.select{|doc, count| doc_ids.include?(doc) }.map{|doc, count| count }.reduce(0, :+), 'document_count' => doc_ids.size }
    end
    docs_missing = docs_with_counts.keys - docs_included
    docs = nil
    if docs_missing.any?
      result['Unknown'] = { option => 'Unknown', 'hit_count' => 0, 'document_count' => 0 } unless result.has_key?('Unknown')
      result['Unknown']['hit_count'] += docs_with_counts.select{|doc, count| docs_missing.include?(doc) }.map{|doc, count| count }.reduce(0, :+)
      result['Unknown']['document_count'] += docs_missing.size
    end
    return result.values.flatten.select{|x| x['hit_count'] > 0}
  end
  
  def get_filtered_word_count(filter)
    start_time = Time.now
    docs = filter_documents(filter)
    duration = (Time.now - start_time) * 1000
    p "filter_documents took #{duration.to_s} ms and returned #{docs.size} documents"
    set_size = (docs.size / 10).round + 1
    threads = []
    docs.each_slice(set_size) do |set|
      threads << Thread.new do
        Thread.current[:output] = set.map {|doc| get_document_token_count(doc)}.reduce(0, :+)
      end
    end
    count = threads.each{ |thread| thread.join }.map{ |thread| thread[:output] }.reduce(0, :+)
    duration = (Time.now - start_time) * 1000
    p "get_filtered_word_count took #{duration.to_s} ms and counted #{count} words"
    count
  end
  
  def get_group_options(view, namespace)
    groups = {}
    if view == 8
      groups['hit'] = []
      groups['left'] = []
      groups['right'] = []
      ['hit','left','right'].each do |position|
        ['text','lemma','pos','phonetic'].each do |annotation|
          groups[position] << [annotation, position.eql?('hit') ? position+'_'+annotation : annotation+'_'+position]
        end
      end
    end
    
    get_metadata_group_options({}, namespace).each do |group, data|
      group = I18n.translate(:"#{group}").capitalize
      if !groups.has_key?(group)
        groups[group] = []
      end
      data.each do |arr|
        field = I18n.translate(:"#{arr[0]}")
        groups[group] << [field, arr[1]]
      end
    end
    
    groups.sort_by {|k, v| [k, v] }
  end
  
  # Load paginated list of metadata in index
  def get_metadata(number, offset, sort, order)
    if @whitelab.respond_to?(:get_metadata)
      @whitelab.get_metadata(number, offset, sort, order)
    else
      fields = []
      @metadata.each do |group, gdata|
        gdata.keys.select{|key| !key.include?("\.") }.each{|key| fields << generate_metadatum_object(group,key) }
      end
      data = []
      fields.uniq[offset..offset+number].each do |metadatum|
        data << reformat_metadatum(metadatum)
      end
      return { 'total' => fields.size, 'metadata' => data }
    end
  end
  
  def get_metadatum(metadatum)
    group = metadatum[:group]
    key = metadatum[:key]
    mgroup = @metadata[group]
    group_exists = mgroup != nil
    if !group_exists || !mgroup.has_key?(key)
      mfile = metadatum_file(metadatum)
      generate_metadatum_file(metadatum, mfile) if !File.exists?(mfile)
      mgroup = {} unless group_exists
      mgroup[key] = load_metadatum_file(mfile)
    end
    mgroup[key]
  end
  
  def get_total_word_count
    tcount = Rails.configuration.x.total_token_count
    if tcount <= 0
      tcount = set_total_word_count
    end
    tcount
  end
  
  def load_corpora
    values, vcount = load_values(generate_metadatum_object('Corpus', 'title'))
    values
  end
  
  def load_values(metadata_obj)
    data = metadata_obj.has_key?('values') ? metadata_obj : get_metadatum(metadata_obj)
    return data['values'], data['value_count']
  end
  
  def reformat_metadatum_values(metadatum)
    data = []
    metadatum['values'].each do |value|
      docs = get_documents_matching_values(metadatum, [value])
      obj = { 'value' => value, 'document_count' => docs.size, 'corpus_counts' => { 'corpora' => [], 'counts' => [] } }
      docs.each do |doc_id|
        doc = get_document(doc_id)
        unless obj['corpus_counts']['corpora'].include?(doc['corpus'])
          obj['corpus_counts']['corpora'] << doc['corpus']
          obj['corpus_counts']['counts'] << 0
        end
        obj['corpus_counts']['counts'][obj['corpus_counts']['corpora'].index(doc['corpus'])] += 1
      end
      data << obj
    end
    data
  end
  
  def load_values_from_server(number, offset, sort, order, group, key)
    data = []
    metadatum = generate_metadatum_object(group, key)
    group = metadatum[:group]
    key = metadatum[:key]
    @whitelab.get_metadatum_values_by_group_and_key(number, 0, "label", "asc", group, key).each do |value|
      data << value.kind_of?(Hash) ? value['value'] : value
    end
    data
  end
  
  def save_metadata
    write_file(metadata_file, { 'metadata' => @metadata })
  end
  
  def update_metadatum(metadatum, updates)
    if @whitelab.respond_to?(:update_metadatum)
      @whitelab.update_metadatum(metadatum, updates)
    else
      metadatum = get_metadatum(metadatum)
      updates.each do |k,v|
        metadatum[k] = v
      end
      save_metadata
    end
  end
  
  private
  
  def filter_to_hash(filter)
    filters = {}
    filter[1, filter.length - 2].split(')AND(').each do |filter_part|
      label, unstripped_value = filter_part.split(/\!*=/)
      group = label.split('_')[0]
      key = label.sub(group+'_','')
      has_group = filters.has_key?(group)
      matches = has_group && filters[group].has_key?(key) ? filters[group][key] : { :positive => [], :negative => [] }
      matches[filter_part.eql?("#{label}!=#{unstripped_value}") ? :negative : :positive] << strip_value(unstripped_value)
      filters[group] = {} unless has_group
      filters[group][key] = matches
    end
    filters
  end
  
  def generate_documents_file(documents_file)
    Rails.logger.info "Generating documents file at #{documents_file}"
    write_file(documents_file, { "documents" => @whitelab.get_document_list })
  end
  
  def generate_metadata_file(metadata_file)
    Rails.logger.info "Generating metadata file at #{metadata_file}"
    metadata = @whitelab.get_metadata_from_server(0, 0, nil, nil)
    data = {}
    metadata.each do |mm|
      metadatum = generate_metadatum_object(mm[:group], mm[:key])
      group = metadatum[:group]
      metadatum[:values] = generate_metadatum_file(metadatum)
      metadatum[:value_count] = metadatum[:values].size
      data[group] = {} unless data.has_key?(group)
      data[group][metadatum[:key]] = metadatum
    end
    write_file(metadata_file, { "metadata" => data })
  end
  
  def generate_metadatum_file(metadatum, mfile = nil)
    mfile = metadatum_file(metadatum) if !mfile
    if File.exists?(mfile)
      return read_file(mfile, 'values').keys
    end
    Rails.logger.info "Generating metadatum file at #{mfile}"
    data = {}
    group = metadatum[:group]
    key = metadatum[:key]
    @whitelab.get_metadatum_values_by_group_and_key(METADATUM_VALUES_MAX, 0, "label", "asc", group, key).each do |value|
      data[value] = document_ids_to_indices(@whitelab.get_document_id_list(group.eql?('Metadata') ? "#{key}=\"#{value}\"" : "#{group}_#{key}=\"#{value}\""))
    end
    write_file(mfile, { "values" => data })
    data.keys
  end
  
  def get_documents_matching_values(metadatum, values, inverted = false)
    return [] if !values.any?
    docs = []
    read_file(metadatum_file(metadatum), 'values').each do |opt, doc_indices|
      included = values.include?(opt)
      docs.push(*doc_indices) if (!inverted && included) || (inverted && !included)
    end
    docs.uniq.map{|doc_index| @documents.keys[doc_index.to_i] }
  end
  
  # Load options for grouping by metadatum
  def get_metadata_group_options(groups, namespace)
    @metadata.each do |group, keys|
      keys.each do |key, data|
        unless key.include?("\.") || (namespace.eql?('explore') && data.has_key?('explorable') && data['explorable'].eql?('false')) || 
          (namespace.eql?('search') && data.has_key?('searchable') && data['searchable'].eql?('false'))
          tr_group = group_translation_key(data['group'])
          groups[tr_group] = [] unless groups.has_key?(tr_group)
          groups[tr_group] << [key_translation_key(key), data['label']]
        end
      end
    end
    groups
  end
  
  def metadata_file
    Rails.root.join("config", "metadata_#{@whitelab.get_backend_type}.#{@format}")
  end
  
  def metadatum_file(metadatum)
    group = metadatum.has_key?(:group) ? metadatum[:group] : metadatum['group']
    key = metadatum.has_key?(:key) ? metadatum[:key] : metadatum['key']
    Rails.root.join("config", "metadata_#{@whitelab.get_backend_type}", "#{group}.#{key}.#{@format}")
  end
  
  def read_file(file, key)
    @format.eql?(:json) ? JSON.parse(File.read(file))[key] : YAML.load_file(file)[key]
  end
  
  def reformat_metadatum(metadatum_obj)
    metadatum = get_metadatum(metadatum_obj)
    unless metadatum.keys.select{|key| key.start_with?('document_count_')}.any?
      corpus_docs = {}
      metadata, vc = load_values(metadatum)
      metadata.each do |value|
        get_documents_matching_values(metadatum, [value]).each do |doc_id|
          doc = @documents[doc_id]
          corpus_docs[doc['corpus']] = [] unless corpus_docs.has_key?(doc['corpus'])
          corpus_docs[doc['corpus']] << doc_id unless corpus_docs[doc['corpus']].include?(doc_id)
        end
      end
      metadatum['document_count'] = 0
      corpus_docs.each do |corpus, docs|
        docs = docs.uniq.size
        metadatum['document_count'] += docs
        metadatum['document_count_'+corpus] = docs
      end
      save_metadata
    end
    if !metadatum.keys.include?('value_count') || metadatum['value_count'] <= 0 || metadatum['value_count'] == METADATUM_VALUES_MAX
      metadatum['value_count'] = load_values_from_server(0, 0, "label", "asc", metadatum['group'], metadatum['key']).size
      save_metadata
    end
    return metadatum
  end
  
  def set_total_word_count
    tcount = get_filtered_word_count(nil)
    Rails.configuration.x.total_token_count = tcount
    tcount
  end
  
  # Strip quotes from metadatum value
  def strip_value(value)
    value.chomp('"').reverse.chomp('"').reverse
  end
  
  def write_file(outfile, data)
    dir = File.dirname(outfile)
    FileUtils.mkpath(dir) unless File.exists?(dir)
    File.open(outfile, 'w', external_encoding: 'ASCII-8BIT') do |file|
      @format.eql?(:yml) ? YAML.dump(data, file) : file.write(data.to_json)
    end
  end
  
end