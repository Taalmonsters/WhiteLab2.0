Whitelab.explore = {
	
	init : function() {
		
		if ($('#metadata-filters').length > 0)
			Whitelab.metadata.init();

		if ($("#main-div[data-namespace='explore'] #query-details").length > 0) {
			var id = $('#query-details').data("query-id");
			$.getScript('/explore/details/id/'+id+'.js');
		}

		if ($("#document-display").length > 0)
			Whitelab.document.init();
		
		if ($("#main-div[data-namespace='explore'] div#ngrams").length > 0)
			Whitelab.explore.ngrams.init();
		
		if ($("#main-div[data-namespace='explore'] div#statistics").length > 0)
			Whitelab.explore.statistics.init();
		
		if ($("#main-div[data-namespace='explore'] div#results").length > 0)
			Whitelab.explore.result.init();
		
		if ($('#corpora div#display').length > 0)
			Whitelab.explore.corpora.init();
	},
	
	getQueryResult : function(number,offset) {
		var id = $('div#result-pane').data("query-id");
		$.getScript('/explore/result/id/'+id+'.js?number='+number+'&offset='+offset);
	},
	
	corpora : {
		
		init : function() {
			
			var option = $('#display').data('option');
			var filter = $('#display').data('filter');
			Whitelab.explore.corpora.loadTreemap(option, filter);
			Whitelab.explore.corpora.loadBubbleChart(option, filter);
			
		},
		
		loadBubbleChart : function(option, filter) {
			$.getScript('/explore/bubble/option/'+option+'.js?filter='+filter);
		},
		
		loadTreemap : function(option, filter) {
			$.getScript('/explore/treemap/option/'+option+'.js?filter='+filter);
		}
		
	},
	
	ngrams : {
		
		init : function() {
			
			Whitelab.explore.ngrams.parseQueryToInterface($('#ngrams').data('query-pattern'),$('#ngrams').data('ngram-size'),$('#ngrams').data('query-group'));
			
		},
		
		parseQueryToInterface : function(pattern, size, group) {
			Whitelab.cql.cqlToNgramsInterface(pattern, size, group);
		},
		
		getPatternFromInput : function() {
			var parts = new Array();
			var size = $("#size").val();
			for (var i = 1; i <= size; i++) {
				var type = $("select#type-"+i+" option:selected").val();
				var value = $("#field-"+i+" .field-input").val();
				if (type === 'pos' && typeof value === 'undefined')
					value = $("#field-"+i+" .field-input").find(':selected').val();
				if (value.length == 0) {
					parts.push("[]");
				} else if (value.match(/^\$[1-5]$/)) {
					parts.push("["+value+"]");
				} else {
					parts.push("["+type+'="'+value+'"]');
				}
			}
			var query = parts.join("");
			query = query.replace("[][][][][]","[]{5}");
			query = query.replace("[][][][]","[]{4}");
			query = query.replace("[][][]","[]{3}");
			query = query.replace(/\[\]\[\]/g,"[]{2}");
			
			return query;
		},
		
		setTokenInput : function(item, value) {
			Whitelab.debug("Whitelab.explore.ngrams.setTokenInput");
			var f = $(item).data("field");
			var typeValue = $(item).find(":selected").val();
			if (typeValue == "pos")
				$.getScript('/interface/pos/select.js?element_class=field-input&element=%23field-'+f+'&value='+value);
			else
				$("#field-"+f).html('<input class="field-input" type="text">');
		},
		
		submitForm : function() {
			var patt = Whitelab.explore.ngrams.getPatternFromInput();
		    var filterString = Whitelab.metadata.getFilterString();
		    var listType = $("#listtype").val();
		    if (listType.length > 0 && patt.length > 0) {
		    	var selectedTokenCount = $('span.metadata-selected-absolute').data('selected-tokens');
		    	if (selectedTokenCount <= Whitelab.metadata.filterTokenSafeLimit || confirm("You have selected a subcorpus of over "+Whitelab.metadata.filterTokenSafeLimit+" tokens. Please note that this query, on first execution, may take a considerable amount of time to complete. Proceed with caution.\n\nContinue?")) {
		    		$('#ngrams-input-form #patt').val(patt);
			    	$('#ngrams-input-form #filter').val(filterString);
			    	$('#ngrams-input-form').submit();
		    	}
		    } else {
		    	var msg = [];
		    	if (patt.length == 0)
		    		msg.push("Please enter a query.");
		    	if (listType.length == 0)
		    		msg.push("Please select a list type.");
		    	alert(msg.join("\n"));
		    }
		}
		
	},
	
	statistics : {
		
		init : function() {
		},
		
		submitForm : function() {
			var filterString = Whitelab.metadata.getFilterString();
		    var listType = $("#listtype").val();
		    if (filterString.length > 0 && listType.length > 0) {
		    	var selectedTokenCount = $('span.metadata-selected-absolute').data('selected-tokens');
		    	if (selectedTokenCount <= Whitelab.metadata.filterTokenSafeLimit || confirm("You have selected a subcorpus of over "+Whitelab.metadata.filterTokenSafeLimit+" tokens. Please note that this query, on first execution, may take a considerable amount of time to complete. Proceed with caution.\n\nContinue?")) {
		    		$('#statistics-input-form #filter').val(filterString);
			    	$('#statistics-input-form').submit();
		    	}
		    } else {
		    	var msg = [];
		    	if (filterString.length == 0)
		    		msg.push("Please define a metadata filter.");
		    	if (listType.length == 0)
		    		msg.push("Please select a list type.");
		    	alert(msg.join("\n"));
		    }
		}
		
	},
	
	result : {
		
		init : function() {
			
			var id = $('div#result-pane').data("query-id");
			$.getScript('/explore/result/id/'+id+'.js');
			
		}
	}
};

$(document).on('click', '#corpora-treemap-update', function(e) {
	$('#display').html('<span class="loading"></span>');
	var filter = Whitelab.metadata.getFilterString();
	window.location = '/explore/corpora?option='+$('#corpora-treemap-select').val()+'&filter='+filter;
});

$(document).on('click', '#ngrams-submit-form', function(e) {
    e.preventDefault();
    e.stopPropagation();
    Whitelab.explore.ngrams.submitForm();
});

$(document).on('click', '#ngrams-reset-form', function(e) {
    e.preventDefault();
    window.location = '/explore/ngrams';
});

$(document).on('change', '#ngrams #size', function(e) {
	e.preventDefault();
	var n = parseInt($(this).val());
	var i = 1;
	Whitelab.debug("N: "+n+", I: "+i);
	for (i; i <= n; i++) {
		Whitelab.debug("ENABLE "+i);
		$('#type-'+i).prop("disabled", false);
		$("#field-"+i+" .field-input").prop("disabled", false);
	}
	if (n < 5) {
		for (i = n; i < 5; i++) {
			var j = i + 1;
			Whitelab.debug("DISABLE "+j);
			$('#type-'+j).prop("disabled", "disabled");
			$("#field-"+j+" .field-input").val('');
			$("#field-"+j+" .field-input").prop("disabled", "disabled");
		}
	}
});

$(document).on('change', '#ngrams select.token-type', function(e) {
	e.preventDefault();
	Whitelab.explore.ngrams.setTokenInput(this, null);
});

$(document).on('click', '#statistics-input-form button.submit', function(e) {
    e.preventDefault();
    e.stopPropagation();
    Whitelab.explore.statistics.submitForm();
});

$(document).on('click', '#statistics-input-form button.reset', function(e) {
    e.preventDefault();
    window.location = '/explore/statistics';
});

$(document).on('click', 'a.explore-statistics-tab', function(e) {
	e.preventDefault();
    e.stopPropagation();
	if (!$(this).parent().hasClass("active")) {
		$(this).parent().parent().find("li.active").first().removeClass("active");
		$(this).parent().addClass("active");
		$("#document-display div.tab-content").html('<span class="loading"></span>');
    	$('#statistics-input-form #view').val($(this).data("view"));
    	if ($(this).data("offset") != null) {
    		$('#statistics-input-form #offset').val($(this).data("offset"));
    		$('#statistics-input-form #number').val($(this).data("number"));
    	}
	    Whitelab.explore.statistics.submitForm();
	}
});

$(document).on('click', '#main-div[data-namespace="explore"] button.show-document', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var docpid = $(this).data("docpid");
	window.location = '/explore/document/'+docpid;
});

$(document).on('click', '#main-div[data-namespace="explore"] tr.hit-row', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var docpid = $(this).data("docpid");
	var f = $(this).data("first-index");
	var l = $(this).data("last-index");
	if ($("#"+docpid+"_"+f+"_"+l).html().length == 0) {
		$.getScript('/explore/kwic.js?docpid='+docpid+'&first_index='+f+'&last_index='+l+'&size=50');
	}
	$("#"+docpid+"_"+f+"_"+l).toggleClass("hidden");
});

$(document).on('click', '#main-div[data-namespace="explore"] tr.doc-row', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var docpid = $(this).data("docpid");
	var hits = $(this).data("hits");
	var qid = $("#result-pane").data("query-id");
	if ($("#"+docpid).html().length == 0) {
		$.getScript('/explore/doc_hits/id/'+qid+'.js?view=1&docpid='+docpid+'&hits='+hits);
	}
	$("#"+docpid).toggleClass("hidden");
});
