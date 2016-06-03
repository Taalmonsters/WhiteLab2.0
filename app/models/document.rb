class Document
  include ActiveModel::Model
  include ActionView::Helpers::DataFormatHelper
  
  attr_accessor :xmlid, :patt, :content
  
  validates :xmlid, presence: true
  
  def self.growth(query)
    vocab_growth = { 'types' => [{ name: '', x: 0, y: 0 }], 'lemmas' => [{ name: '', x: 0, y: 0 }] }
    total = 0
    t = 0, l = 0
    MetadataHandler.instance.filter_documents(query.filter).each do |doc|
      xmlid = MetadataHandler.instance.get_document_id(doc)
      document = Document.new({:xmlid => xmlid})
      token_count = document.token_count
      contents = document.get_content
      types = contents['word']
      type_growth = Array.new(total, 0)
      types.uniq.each{|x| type_growth[types.index(x)] = 1 }
      lemmas = contents['lemma']
      lemma_growth = Array.new(total, 0)
      lemmas.uniq.each{|x| lemma_growth[lemmas.index(x)] = 1 }
      (total..total+token_count-1).to_a.each do |i|
        t += type_growth[i]
        l += lemma_growth[i]
        vocab_growth['types'] << { name: types[i], x: i+1, y: t }
        vocab_growth['lemmas'] << { name: lemmas[i], x: i+1, y: l }
      end
    end
    return { title: 'Vocabulary growth', data: [{ name: 'word_types', color: '#A90C28', data: vocab_growth['types'] }, { name: 'lemmas', color: '#53c4c3', data: vocab_growth['lemmas'] }] }
  end
  
  def audio_file(format = 'mp3')
    return "#{Rails.configuration.x.audio_dir}/#{format}/#{xmlid}.#{format}"
  end
  
  def growth
    total = self.token_count
    vocab_growth = { 'types' => [{ name: '', x: 0, y: 0 }], 'lemmas' => [{ name: '', x: 0, y: 0 }] }
    contents = self.get_content
    types = contents['word']
    type_growth = Array.new(total, 0)
    types.uniq.each{|x| type_growth[types.index(x)] = 1 }
    lemmas = contents['lemma']
    lemma_growth = Array.new(total, 0)
    lemmas.uniq.each{|x| lemma_growth[lemmas.index(x)] = 1 }
    t = 0, l = 0
    (0..total-1).to_a.each do |i|
      t += type_growth[i]
      l += lemma_growth[i]
      vocab_growth['types'] << { name: types[i], x: i+1, y: t }
      vocab_growth['lemmas'] << { name: lemmas[i], x: i+1, y: l }
    end
    return { title: 'Vocabulary growth', data: [{ name: 'word_types', color: '#A90C28', data: vocab_growth['types'] }, { name: 'lemmas', color: '#53c4c3', data: vocab_growth['lemmas'] }] }
  end
  
  def statistics
    contents = self.get_content
    total = self.token_count
    type_count = contents["word"].uniq.count
    return { "token_count" => total, "type_count" => type_count, "type-token ratio" => type_count / total, "lemma_count" => contents["lemma"].uniq.count }
  end
  
  def metadata
    return WhitelabBackend.instance.get_document_metadata(xmlid)
  end
  
  def pos_distribution
    return { title: 'Token/POS Distribution', data: self.get_content['pos'].group_by{|pos| pos.split('(')[0] }.each{|_,list| list.size }.sort_by{|_, freq| freq }.reverse.map{|pos_head,freq| { name: pos_head, y: freq } } }
  end
  
  def content
    total = self.token_count
    contents = self.get_content
    paragraphs = (0..total-1).to_a.group_by{|i| contents['xmlid'][i].split(/\.s\./)[0].sub(/^.*p\./,'').to_i }.map{|par, words|
      {
        par => {
          'sentences' => words.group_by{|i| data['xmlid'][i].split(/\.w\./)[0].sub(/^.*s\./,'').to_i}.map{|sen, tokens|
            {
              sen => {
                'tokens' => tokens.map{|i|
                  {
                    'xmlid' => "WR-P-P-D-0000000005.#{data['xmlid'][i]}",
                    'word_type' => contents['word'][i],
                    'lemma' => contents['lemma'][i],
                    'pos_tag' => contents['pos'][i],
                    'pos_head' => contents['pos'][i].split('(')[0],
                    'phonetic' => contents['phonetic'][i],
                    'begin_time' => contents['begin_time'][i],
                    'end_time' => contents['end_time'][i],
                    'sentence_speaker' => contents['speaker'][i]
                  }
                },
                'sentence_speaker' => contents['speaker'][tokens[0]],
                'begin_time' => contents['begin_time'][tokens[0]],
                'end_time' => contents['end_time'][tokens[tokens.size-1]]
              }
            }
          },
          'paragraph_type' => contents.has_key?('paragraph_type') ? contents['paragraph_type'] : 'p'
        }
      }
    }
    return { 'paragraphs' => paragraphs, 'audio_file' => self.audio_file, 'total_sentence_count' => contents['xmlid'].select{|x| x =~ /w\.1$/ }.size, 'begin_time' => contents['begin_time'][0], 'end_time' => contents['end_time'][total-1] }
  end
  
  def xml_content
    return WhitelabBackend.instance.get_document_content(self.xmlid)
  end
  
  def token_count
    return MetadataHandler.instance.get_document_token_count(xmlid)
  end
  
  private
  
  def get_content
    return WhitelabBackend.instance.get_document_snippet(self.xmlid, 0, self.token_count)['match']
  end
  
end