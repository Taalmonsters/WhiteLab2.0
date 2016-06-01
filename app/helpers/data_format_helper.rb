# Data formatting helper methods
module DataFormatHelper
  
  # Convert view to search path for the backend
  def view_to_path(view)
    prefix = ""
    suffix = "hits"
    if view == 2 || view == 16
      suffix = "docs"
    end
    if WhitelabBackend.instance.get_backend_type.eql?('neo4j') && (view == 8 || view == 16)
      prefix = "grouped_"
    end
    prefix+suffix
  end
  
  def group_to_label(group)
    if group.eql?('text')
      'word'
    else
      group
    end
  end
  
  def group_translation_key(group)
    :"metadata_groups.keys.#{group}"
  end
  
  def key_translation_key(key)
    :"metadata_keys.keys.#{key}"
  end
  
  # Format percentage
  def format_percentage(pro,d)
    pro.round(d).to_s+" %"
  end
  
  # Format Neo4j vocabulary growth output as Highcharts line chart
  def format_for_vocabulary_growth(data)
    growth = { 'types' => [{ name: '', x: 0, y: 0 }], 'lemmas' => [{ name: '', x: 0, y: 0 }] }
    types_seen = []
    t = 0
    lemmas_seen = []
    l = 0
    data.each do |token|
      t = t + 1
      if !types_seen.include?(token['word_type'])
        types_seen << token['word_type']
      end
      l = l + 1
      if !lemmas_seen.include?(token['lemma'])
        lemmas_seen << token['lemma']
      end
      growth['types'] << { name: token['word_type'], x: t, y: types_seen.size }
      growth['lemmas'] << { name: token['lemma'], x: l, y: lemmas_seen.size }
    end
    { title: 'Vocabulary growth', data: [{ name: 'word_types', color: '#A90C28', data: growth['types'] }, { name: 'lemmas', color: '#53c4c3', data: growth['lemmas'] }] }
  end
  
  # Format corpus composition as Highcharts bubble chart
  def format_for_bubble_chart(data, title, filtered_token_count)
    max_doc_count = 0
    if data.any?
      data.sort!{|group| group['document_count'] }.reverse!
      max_doc_count = data[0]['document_count']
      data.map!{|group| { 'name' => group[title], 'x' => group['hit_count'], 'y' => group['hit_count'] / group['document_count'], 'z' => group['document_count'] } }
    else
      data = [{ 'name' => 'Unknown', 'x' => filtered_token_count, 'y' => 0, 'z' => 0 }]
    end
    return { "title" => title, "data" => data, "max_doc_count" => max_doc_count }
  end
  
  # Format corpus composition as Highcharts treemap
  def format_for_treemap(data, title, filtered_token_count)
    if data.any?
      data.map!{|group| { 'name' => group[title], 'size' => group['hit_count'] } }
    else
      data = [{ 'name' => 'Unknown', 'size' => 0 }]
    end
    return { 'name' => title, 'size' => filtered_token_count, 'children' => data }
  end
  
  # Convert timestamp to seconds
  def time_to_seconds(t)
    parts = t.split(":");
    parts[2].to_f + (60 * parts[1].to_i) + (3600 * parts[0].to_i)
  end
  
  # Convert operator to value string
  def operator_to_value(op)
    if op.eql?('!=')
      return 'not'
    end
    'is'
  end
  
  # Convert array of hashes to CSV with header row
  def aoh_to_csv(aoh)
    csv = []
    csv << aoh[0].keys.join(",")
    aoh.each do |row|
      if !row.blank?
        data = []
        aoh[0].keys.each do |key|
          data << row[key]
        end
        csv << '"'+data.join('","')+'"'
      end
    end
    csv.join("\n")
  end
  
end