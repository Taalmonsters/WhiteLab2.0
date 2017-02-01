# Module for documents, not persisted to the database
class Document
  include ActiveModel::Model
  include DataFormatHelper

  # The document model uses 3 attributes: xmlid (document pid), patt (query pattern), and content (document content)
  attr_accessor :xmlid, :patt, :content

  validates :xmlid, presence: true

  # Assemble the vocabulary growth data array for all documents matching a query
  def self.growth(query)
    vocab_growth = { 'types' => [{ ggroup: 'types', name: '', x: 0, x2: 0.0, y: 0, y2: 0.0 }], 'lemmas' => [{ ggroup: 'lemmas', name: '', x: 0, x2: 0.0, y: 0, y2: 0.0 }] }
    total = 0
    t = 0
    l = 0
    type_growth = []
    lemma_growth = []
    types = []
    lemmas = []
    d = 0
    MetadataHandler.instance.filter_documents(query.filter).each do |doc|
      d += 1
      xmlid = MetadataHandler.instance.get_document_id(doc)
      document = Document.new({:xmlid => xmlid})
      contents = document.get_content
      total += document.token_count
      types += contents['word']
      lemmas += contents['lemma']
    end
    type_growth = Array.new(total, 0)
    lemma_growth = Array.new(total, 0)
    total_unique_types = 0
    total_unique_lemmas = 0
    types.uniq.each{|x| type_growth[types.index(x)] = 1; total_unique_types += 1; }
    lemmas.uniq.each{|x| lemma_growth[lemmas.index(x)] = 1; total_unique_lemmas += 1; }
    (0..total-1).to_a.each do |i|
      t += type_growth[i]
      l += lemma_growth[i]
      vocab_growth['types'] << {
        ggroup: 'types',
        name: types[i],
        x: i+1,
        x2: (((i+1).to_f / total) * 100).round(1),
        y: t,
        y2: ((t.to_f / total_unique_types) * 100).round(1)
      }
      vocab_growth['lemmas'] << {
        ggroup: 'lemmas',
        name: lemmas[i],
        x: i+1,
        x2: (((i+1).to_f / total) * 100).round(1),
        y: l,
        y2: ((l.to_f / total_unique_lemmas) * 100).round(1)
      }
    end
    return { document_count: d, hit_count: total, title: I18n.t(:"chart_labels.keys.growth_title"), labels: { unique: I18n.t(:"other.keys.unique").capitalize, progress: I18n.t(:"other.keys.progress").capitalize }, data: [{ name: I18n.t(:"data_labels.keys.word_type").pluralize, color: '#A90C28', data: vocab_growth['types'] }, { name: I18n.t(:"data_labels.keys.lemma").pluralize, color: '#53c4c3', data: vocab_growth['lemmas'] }] }
  end

  # Return the audio file for a document
  def audio_file(format = 'mp3')
    return "#{Rails.configuration.x.audio_dir}/#{format}/#{xmlid}.#{format}"
  end

  # Assemble the vocabulary growth data array for a document
  def growth
    total = self.token_count
    vocab_growth = { 'types' => [{ ggroup: 'types', name: '', x: 0, x2: 0.0, y: 0, y2: 0.0 }], 'lemmas' => [{ ggroup: 'lemmas', name: '', x: 0, x2: 0.0, y: 0, y2: 0.0 }] }
    contents = self.get_content
    types = contents['word']
    total_unique_types = 0
    type_growth = Array.new(total, 0)
    types.uniq.each{|x| type_growth[types.index(x)] = 1; total_unique_types += 1; }
    lemmas = contents['lemma']
    total_unique_lemmas = 0
    lemma_growth = Array.new(total, 0)
    lemmas.uniq.each{|x| lemma_growth[lemmas.index(x)] = 1; total_unique_lemmas += 1; }
    t = 0
    l = 0
    (0..total-1).to_a.each do |i|
      t += type_growth[i]
      l += lemma_growth[i]
      vocab_growth['types'] << {
        ggroup: 'types',
        name: types[i],
        x: i+1,
        x2: ActionController::Base.helpers.number_with_precision(((i+1).to_f / total) * 100, precision: 1, separator: I18n.t(:"other.keys.numeric_separator")),
        y: t,
        y2: ActionController::Base.helpers.number_with_precision((t.to_f / total_unique_types) * 100, precision: 1, separator: I18n.t(:"other.keys.numeric_separator"))
      }
      vocab_growth['lemmas'] << {
        ggroup: 'lemmas',
        name: lemmas[i],
        x: i+1,
        x2: ActionController::Base.helpers.number_with_precision(((i+1).to_f / total) * 100, precision: 1, separator: I18n.t(:"other.keys.numeric_separator")),
        y: l,
        y2: ActionController::Base.helpers.number_with_precision((l.to_f / total_unique_lemmas) * 100, precision: 1, separator: I18n.t(:"other.keys.numeric_separator"))
      }
    end
    return { title: I18n.t(:"chart_labels.keys.growth_title"), labels: { unique: I18n.t(:"other.keys.unique").capitalize, progress: I18n.t(:"other.keys.progress").capitalize }, data: [{ name: I18n.t(:"data_labels.keys.word_type").pluralize, color: '#A90C28', data: vocab_growth['types'] }, { name: I18n.t(:"data_labels.keys.lemma").pluralize, color: '#53c4c3', data: vocab_growth['lemmas'] }] }
  end

  # Return simple document statistics
  def statistics
    contents = self.get_content
    total = self.token_count
    type_count = contents["word"].uniq.count
    return { "token_count" => total, "type_count" => type_count, "type-token ratio" => type_count / total, "lemma_count" => contents["lemma"].uniq.count }
  end

  # Retrieve the document metadata from the backend
  def metadata
    return WhitelabBackend.instance.get_document_metadata(xmlid)
  end

  # Retrieve the distribution of PoS tags for a document
  def pos_distribution
    return { title: I18n.t(:"chart_labels.keys.pos_pie_title"), data: self.get_content['pos'].group_by{|pos| pos.split('(')[0] }.each{|_,list| list.size }.sort_by{|_, freq| freq }.reverse.map{|pos_head,freq| { name: pos_head, y: freq.size } } }
  end

  # Retrieve the paginated content of a document
  def content(offset = 0, number = 50)
    total = self.token_count
    contents = self.get_content
    allowed_indices = contents['xmlid'].select{|id| id =~ /\.1$/ }.map{|id| contents['xmlid'].index(id) }.slice(offset,number+1)
    paragraphs = (allowed_indices.first..allowed_indices.last-1).to_a.group_by{|i| contents['xmlid'][i].split(/\.s\./)[0].sub(/^.*p\./,'').to_i }.map{|par, words|
      {
        par => {
          'paragraph_type' => contents.has_key?('paragraph_type') ? contents['paragraph_type'] : 'p',
          'sentences' => words.group_by{|i| contents['xmlid'][i].split(/\.w\./)[0].sub(/^.*s\./,'').to_i}.map{|sen, tokens|
            {
              sen => {
                'sentence_speaker' => contents['speaker'][tokens[0]],
                'begin_time' => contents['begin_time'][tokens[0]],
                'end_time' => contents['end_time'][tokens.last-1],
                'tokens' => tokens.map{|i|
                  {
                    'xmlid' => "#{self.xmlid}.#{contents['xmlid'][i]}",
                    'word_type' => contents['word'][i],
                    'lemma' => contents['lemma'][i],
                    'pos_tag' => contents['pos'][i],
                    'pos_head' => contents['pos'][i].split('(')[0],
                    'phonetic' => contents['phonetic'][i],
                    'begin_time' => contents['begin_time'][i],
                    'end_time' => contents['end_time'][i],
                    'sentence_speaker' => contents['speaker'][i]
                  }
                }
              }
            }
          }.reduce(Hash.new, :merge)
        }
      }
    }.reduce Hash.new, :merge
    return { 'paragraphs' => paragraphs, 'audio_file' => self.audio_file, 'total_sentence_count' => contents['xmlid'].select{|x| x =~ /\.1$/ }.size, 'begin_time' => contents['begin_time'][0], 'end_time' => contents['end_time'][total-1] }
  end

  # Retrieve the XML content of a document
  def xml_content
    return WhitelabBackend.instance.get_document_content(self.xmlid)
  end

  # Retrieve the token count of a document
  def token_count
    return MetadataHandler.instance.get_document_token_count(xmlid)
  end

  # Return a snippet of the total document size for a document
  def get_content
    return WhitelabBackend.instance.get_document_snippet(self.xmlid, 0, self.token_count)['match']
  end
  
end