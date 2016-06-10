Whitelab.metadata = {
	filterTokenSafeLimit : 0,
	
	init : function() {
		
		var filter = $('#metadata-filters').data('filter');
		if (filter.length > 0) {
			filter = filter.substr(1,filter.length - 2);
			var parts = filter.split(')AND(');
			for (var i = 0; i < parts.length; i++) {
				var match = parts[i].match(/^(([A-Za-z0-9]+)_)*([A-Za-z0-9_\-]+)(\!*=|\>=*|\<=*)(.+)$/);
				var group = "Metadata";
				if (match[1] != null)
					group = match[1];
				Whitelab.metadata.addMetadataRule(group,match[3],Whitelab.search.operatorToValue(match[4]),match[5].replace(/"/g, ''));
			}
		} else {
			Whitelab.metadata.addMetadataRule(null,null,null,null);
		}
		
	},
	
	addMetadataRule : function(group,key,operator,value) {
		var i = $('.metadata-rule').length;
		while ($('#rule'+i).length > 0) {
			i++;
		}
		if (group && key && operator && value)
			$.getScript('/metadata/rule/new.js?rule_id='+i+'&group='+group+'&key='+key+'&operator='+operator+'&value='+value);
		else
			$.getScript('/metadata/rule/new.js?rule_id='+i);
	},
	
	getFilterString : function() {
		var filters = new Array();
		$("#metadata-rules .rule").each(function( index ) {
			var label = $(this).find(".metadata-key-select").val();
			var input = $(this).find(".metadata-input").val().replace(/&/g,"%26");
			var op = $(this).find(".metadata-operator").val();
			if (op === 'not') {
				op = '!=';
			} else {
				op = '=';
			}
			if (label && input && input.length > 0) {
				var f = label+op+"\""+input+"\"";
				f = f.replace(/field\:/g,"");
				filters.push(f);
			}
		});
		if (filters.length > 0) {
			var filterQuery = "("+filters.join(")AND(")+")";
			return filterQuery;
		}
		return "";
	},
	
	updateCoverage : function() {
		var filterString = Whitelab.metadata.getFilterString();
		if (filterString.length > 0) {
			$('span.metadata-selected-percentage').html('<div class="tiny-loading-icon"></div>');
			$('span.metadata-selected-absolute').html('<div class="tiny-loading-icon"></div>');
			$.getScript('/metadata/coverage.js?filter='+filterString);
		} else {
			$('span.metadata-selected-percentage').html('100.0 %');
			$('span.metadata-selected-absolute').html($('#metadata-filters').data('total-tokens-delimited'));
		}
		Whitelab.metadata.updateTabLinks(filterString);
	},
	
	updateTabLinks : function(filter) {
		var link_ids = [];
		if (Whitelab.namespace === 'search') {
			link_ids = ['extended','advanced','expert'];
		} else if (Whitelab.namespace === 'explore') {
			link_ids = ['corpora','statistics','ngrams'];
		}
		for (var i = 0; i < link_ids.length; i++) {
			if (!$('li#'+link_ids[i]+'_link').hasClass('active')) {
				$('li#'+link_ids[i]+'_link > a').attr('href','/'+Whitelab.namespace+'/'+link_ids[i]+'?filter='+filter);
			}
		}
	}
	
};

$(document).on('change', '.metadata-key-select', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var vals = $(this).val().split('_');
	var group = vals[0];
	var key = $(this).val().replace(group+'_','');
	var rule_id = $(this).parent().parent().attr('id');
	if (group.length > 0 && key.length > 0 && rule_id.length > 0)
		$.getScript('/metadata/'+group+'/'+key+'/values.js?rule_id='+rule_id);
	else {
		$(this).parent().parent().find('select.metadata-input').first().replaceWith('<input class="metadata-input" type="text">');
		Whitelab.metadata.updateCoverage();
	}
});

$(document).on('change', 'select.metadata-input', function(e) {
	e.preventDefault();
	e.stopPropagation();
	Whitelab.metadata.updateCoverage();
});

$(document).on('change', 'select.metadata-operator', function(e) {
	e.preventDefault();
	e.stopPropagation();
	Whitelab.metadata.updateCoverage();
});
