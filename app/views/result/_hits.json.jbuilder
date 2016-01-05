json.query do
  json.id query.id
  json.tab query.tab
	json.CQL query.query
	json.within query.within
	json.sort query.sort
	json.group query.group
	json.query_url query.get_url('id')
end

json.hits query.result do |hit|
  json.hit WordToken.details_for(hit)
end