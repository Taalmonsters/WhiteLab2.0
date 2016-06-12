class Search::QueriesController < QueriesController
  include WhitelabSearch
  
  # Load hits for Search Query in selected document
  def doc_hits
    if @query && params.has_key?(:docpid)
      @target = params[:docpid]
      @query.view = 1
      @query.filter = @query.filter.blank? ? "(id:#{@target})" : "#{@query.filter}AND(id:#{@target})"
      @query.offset = 0
      @query.number = params[:hits]
      @doc_hits = @query.result["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/doc_hits'
      end
    end
  end
  
  # Load documents for Search Query in selected group
  def docs_in_group
    @group_id = params[:group_id]
    if @query
      @query = @query.clone
      @query.filter = @query.filter.blank? ? "("+@query.group+"=\""+params[:docs_group]+"\")" : @query.filter+"AND("+@query.group+"=\""+params[:docs_group]+"\")"
      @query.view = 2
      @query.group = nil
      @query.offset = params[:offset] || 0
      @query.number = 20
      @docs = @query.result["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/docs_in_group'
      end
    end
  end
  
  # Load hits for Search Query in selected group
  def hits_in_group
    @group_id = params[:group_id]
    if @query
      @query = @query.clone
      @query.add_hits_group(params[:hits_group])
      @query.view = 1
      @query.group = nil
      @query.offset = params[:offset] || 0
      @query.number = 20
      @hits = @query.result["results"]
    end
    respond_to do |format|
      format.js do
        render '/result/hits_in_group'
      end
    end
  end
  
  # Load keywords in context for hit
  def kwic
    @target = get_target_from_params
    if @target
      @kwic = @whitelab.get_kwic(params[:docpid], params[:first_index], params[:last_index], params[:size])
    end
    respond_to do |format|
      format.js do
        render '/result/kwic'
      end
    end
  end
  
  private
  
  def get_target_from_params
    docpid = params[:docpid] || ''
    first_index = params.has_key?(:first_index) ? params[:first_index].to_s : ''
    last_index = params.has_key?(:last_index) ? params[:last_index].to_s : ''
    return docpid+'_'+first_index+'_'+last_index if docpid && first_index && last_index
    return nil
  end
  
end
