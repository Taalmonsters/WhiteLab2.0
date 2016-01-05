class Cql::Interpreter
  @i = 0
  @max = 0
  @inside_dq = false
  @inside_sq = false
  
  def json_to_query(json)
    text = []
    json.each do |c,column|
      ctext = []
      column['fields'].each do |field|
        if field.has-key?('pattern')
          ctext << field['pattern']
        end
      end
      if ctext.size == 0
        text << '[]'
      elsif ctext.size == 1
        text << ctext[0]
      else
        if column.has_key?('operator')
          text << '('+ctext.join(operator_to_query(column['operator']))+')'
        else
          text << '('+ctext.join('&')+')'
        end
      end
    end
    text.join(' ')
  end
  
  def operator_to_query(op)
    if op && op.eql?('OR')
      '|'
    else
      '&'
    end
  end
  
  def cql_to_json(cql)
    parse(cql)
  end
  
  def parse(cql)
    @i = 0
    @max = 0
    cql = self.normalize_spaces(cql)
    columns = self.split_columns(cql)
    
    in_brackets = 0
    sets = {}
    keep = []
    columns.each do |c|
      if c.eql?('(')
        in_brackets = in_brackets + 1
        if !sets.has_key?(in_brackets)
          sets[in_brackets] = []
        end
      elsif c.eql?(')')
        if sets[in_brackets].length > 0
          set = process_connectors(sets[in_brackets])
          set = process_quantifiers(set)
          sets.except!(in_brackets)
          in_brackets = in_brackets - 1
          if in_brackets > 0
            sets[in_brackets] << set
          else
            keep.push(set)
          end
        else
          in_brackets = in_brackets - 1
        end
      elsif in_brackets > 0
        sets[in_brackets].push(c)
      else
        set = process_connectors(c)
        set = process_quantifiers(set)
        keep.push(set)
      end
    end
    
    columns = {}
    keep.each_with_index do |column, i|
      columns[i] = process_column_fields(column)
    end
    columns
  end
  
  def normalize_spaces(cql)
    cql.gsub(/\[\]/,'[word=""]').gsub(/ *([\"\'\=\|\&\[\]\(\)]) */,'\1')
  end
  
  def split_columns(cql)
    columns = []
    cql.gsub!(/([\[\]\&\|\(\)\"\"])/) { |p| self.add_nesting_level(p) }
    cql.split("\n").map(&:strip).reject{ |c| c.empty? }.each do |c|
      if c =~ /^[0-9]+\%/
        c2 = c.gsub(/^[0-9]+\%/,'').gsub(' ','')
        if !c2.eql?('')
          columns.push(c2)
        end
      else
        c.split(' ').each do |cc|
          columns.push(cc)
        end
      end
    end
    columns
  end
  
  def process_connectors(column)
    connector = nil
    fields = []
    if column.include?('|')
      connector = 'OR'
      fields = filter_fields(column,'|')
    elsif column.include?('&')
      connector = 'AND'
      fields = filter_fields(column,'&')
    else
      fields = column
    end
    if connector
      { 'connector' => connector, 'fields' => fields }
    else
      { 'fields' => fields }
    end
  end
  
  def process_quantifiers(column)
    if column['fields'].kind_of?(String)
      q = get_quantifier_from_string(column['fields'])
      if q
        column = process_quantifier(column, q)
        # if column.has_key?('repeat_of')
          # return column
        # end
      end
    else
      column['fields'].each_with_index do |field,i|
        if field.kind_of?(String)
          q = get_quantifier_from_string(field)
          if q
            column = process_quantifier(column, q)
            if column.has_key?('repeat_of')
              return column
            end
          end
        else
          column['fields'][i] = process_quantifiers(field)
        end
      end
    end
    column
  end
  
  def process_quantifier(column, q)
    is_repeat = false
    if match = q.match(/^\$([0-9]+)/)
      nr = match.captures[0]
      is_repeat = true
      q.sub!('$'+nr,'')
      column['repeat_of'] = nr.to_i - 1
    end
    if q.length > 0
      column['quantifier'] = q
    end
    if is_repeat
      return column.except!('fields','connector')
    else
      return column
    end
  end
  
  def get_quantifier_from_string(str)
    if str !~ /"$/
      str.split('"')[-1]
    else
      nil
    end
  end
  
  def filter_fields(fields,r)
    keep = []
    fields.each do |field|
      if !field.kind_of?(String) || !field.eql?(r)
        keep << field
      end
    end
    keep
  end
  
  def add_nesting_level(b)
    label = ''
    if b.eql?('[') && !@inside_dq && !@inside_sq
      self.level_up
      label = "\n"+@i.to_s+'%'
    elsif b.eql?(']') && !@inside_dq && !@inside_sq
      self.level_down
    elsif b.eql?('"')
      if @inside_dq
        @inside_dq = false
      else
        @inside_dq = true unless @inside_sq
      end
      label = b
    elsif b.eql?("'")
      if @inside_sq
        @inside_sq = false
      else
        @inside_sq = true unless @inside_dq
      end
      label = b
    elsif ['(',')','&','|'].include?(b) && !@inside_dq && !@inside_sq
      label = "\n"+b+"\n"
    elsif ['&','|','(',')','[',']'].include?(b) && (@inside_dq || @inside_sq)
      label = b
    end
    return label
  end
  
  def level_up
    @i = @i + 1
    if @i > @max
      @max = @i
    end
  end
  
  def level_down
    @i = @i - 1
  end
  
  def process_column_fields(column)
    if column['fields'].kind_of?(String)
      column['fields'] = [process_field(column['fields'])]
    elsif column.has_key?('fields')
      column['fields'].each_with_index do |field,i|
        if field.kind_of?(String)
          column['fields'][i] = process_field(field)
        else
          column['fields'][i] = process_column_fields(field)
        end
      end
    end
    column
  end
  
  def process_field(el)
    field = {}
    if match = el.match(/(word|w|lemma|l|pos|p|)(\!*\=)[\'\"](\(\?[ci]\))*(.+)[\'\"](\{[0-9]+,*[0-9]*\}|\*|\+)*/)
       # || match = el.match(/(w|l|p)\=[\'\"](\(\?[ci]\))*(.+)[\'\"](\{[0-9]+,*[0-9]*\}|\*|\+)*/)
      definition, operator, sensitivity, value, quantifier = match.captures
      field['field'] = self.definition_to_field(definition,value)
      field['pattern'] = value
      field['operator'] = self.operator_to_string(operator)
      if sensitivity && !sensitivity.empty? && sensitivity.eql?('(?c)')
        field['case_sensitive'] = true
      end
      if quantifier && !quantifier.empty?
        field['quantifier'] = quantifier
      end
    elsif el.empty? || el.eql?('word=""')
      field['field'] = 'WordToken'
    else
      field['field'] = 'WordType'
      field['pattern'] = el
    end
    field
  end
  
  def operator_to_string(operator)
    if operator.eql?('!=')
      return 'not_equal'
    end
    'equal'
  end
  
  def definition_to_field(definition,value)
    if ['word','w'].include?(definition)
      return 'WordType'
    elsif ['lemma','l'].include?(definition)
      return 'Lemma'
    elsif ['pos','p'].include?(definition)
      if value =~ /^[A-Z]+$/
        return 'PosHead'
      else
        return 'PosTag'
      end
    end
  end
  
end