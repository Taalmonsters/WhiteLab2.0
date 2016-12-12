class Search::QueriesController < QueriesController
  include WhitelabSearch
  
  def context_options
    @query.group = params[:group] if params.has_key?(:group)
    respond_to do |format|
      format.js do
        render '/result/context_options'
      end
    end
  end
  
  # Load hits for Search Query in selected document
  def doc_hits
    if @query && params.has_key?(:docpid)
      sub_query = @query.dup
      @target = params[:docpid]
      field, id = @metadata_handler.docpid_to_id(@target)
      sub_query.view = 1
      sub_query.filter = "(#{field}:#{id})"
      sub_query.offset = 0
      sub_query.number = params[:hits]
      @doc_hits = sub_query.result(false)["results"]
      sub_query.destroy
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
    @offset = params[:offset].to_i || 0
    if @query
      sub_query = @query.dup
      sub_query.filter = @query.filter.blank? ? "("+@query.group+"=\""+params[:docs_group]+"\")" : @query.filter+"AND("+@query.group+"=\""+params[:docs_group]+"\")"
      sub_query.view = 2
      sub_query.group = nil
      sub_query.offset = @offset
      sub_query.number = 20
      @docs = sub_query.result(false)["results"]
      sub_query.destroy
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
    @offset = params[:offset].to_i || 0
    if @query
      sub_query = @query.dup
      sub_query.add_hits_group(params[:hits_group])
      sub_query.view = 1
      sub_query.group = nil
      sub_query.offset = @offset
      sub_query.number = 20
      @hits = sub_query.result(false)["results"]
      sub_query.destroy
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
