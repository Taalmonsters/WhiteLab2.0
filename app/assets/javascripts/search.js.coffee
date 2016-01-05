$(document).on 'blur', 'input[data-search-view]', ->
  $('#view').val($(this).data("search-view"));
  $('#query').val($(this).val());
  console.log('view: '+$('#view').val()+', query: '+$('#query').val());

# $(document).on 'click', '#metadata button.btn-pagination', ->
  # getMetadataList($(this).data("number"),$(this).data("offset"));
# 
# $(document).on 'click', '#pos-tags button.btn-pagination', ->
  # getPosTagList($(this).data("number"),$(this).data("offset"));
