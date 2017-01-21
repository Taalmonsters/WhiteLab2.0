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
				if (match[2] != null)
					group = match[2];
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
			var label = $(this).find(".metadata-key-select").val().replace("Metadata_", "");
			var input = $(this).find(".metadata-input").val().replace(/&/g,"%26").replace(/\\/g,"%5C");
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
	
	getView : function() {
		var val = $("#metadata-options #show").val();
		var group = $("#metadata-options #group").val();
		if (val === 'hits')
			if (group === '')
				return 1;
			else
				return 8;
		else
			if (group === '')
				return 2;
			else
				return 16;
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

$(document).on('change', '#metadata-filters #show', function(e) {
	var val = $(this).val();
	if (val === 'hits') {
		$('#metadata-filters #group optgroup[label="hit"]').prop('disabled', false);
		$('#metadata-filters #group optgroup[label="left"]').prop('disabled', false);
		$('#metadata-filters #group optgroup[label="right"]').prop('disabled', false);
	} else {
		$('#metadata-filters #group optgroup[label="hit"]').prop('disabled', true);
		$('#metadata-filters #group optgroup[label="left"]').prop('disabled', true);
		$('#metadata-filters #group optgroup[label="right"]').prop('disabled', true);
	}
});

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

$(document).on('change', '#sample_type', function(e) {
	var val = $(this).val();
	if (!val || val.length == 0)
	    val = "sample";
	$("#metadata-filters").find(".sample-size-input").addClass("hidden");
	$("#"+val+"_size").removeClass("hidden");
});

$(document).on('click', '#metadata-accordion .accordion-toggle', function(e) {
    $(this).find(".metadata-header-img").toggleClass("hidden");
});
