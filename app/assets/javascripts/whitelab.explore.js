Whitelab.explore = {
	
	init : function() {
		
		if ($('#metadata-filters').length > 0)
			Whitelab.metadata.init();

//		if ($("#main-div[data-namespace='explore'] #query-details").length > 0) {
//			var id = $('#query-details').data("query-id");
//			$.getScript('/explore/details/id/'+id+'.js');
//		}

		if ($("#document-display").length > 0)
			Whitelab.document.init();
		
		if ($("#main-div[data-namespace='explore'] div#ngrams").length > 0)
			Whitelab.explore.ngrams.init();
		
		if ($("#main-div[data-namespace='explore'] div#statistics").length > 0)
			Whitelab.explore.statistics.init();
		
		if ($("#main-div[data-namespace='explore'] #results").length > 0)
			Whitelab.explore.result.init();
		
		if ($('#corpora div#display').length > 0)
			Whitelab.explore.corpora.init();
	},
	
	getQueryResult : function(number,offset) {
		var id = $('div#result-pane').data("query-id");
		$.getScript('/explore/result/id/'+id+'.js?number='+number+'&offset='+offset);
	},
	
	importXMLQuery: function(e, el, page) {
		e.stopPropagation();
		var file = el.files[0];
		if (file["name"].indexOf("xml") == file["name"].length - 3 || file["name"].indexOf("XML") == file["name"].length - 3) {
			var formData = new FormData();
			formData.append('file', file);
			$.ajax({
		       url : '/explore/'+page+'.json',
		       type : 'POST',
		       data : formData,
		       processData: false,  // tell jQuery not to process the data
		       contentType: false,  // tell jQuery not to set contentType
		       success : function(data) {
		           if (data["error"])
		        	   alert(data["error"]);
		           else if (data["url"])
		        	   window.location = data["url"];
		       }
			});
		} else
			alert("Only XML files allowed!");
	},
	
	removeQuery : function(queryId) {
		$.getScript('/explore/remove/id/'+queryId+'.js');
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

        importGapQuery: function(e, el, run) {
            if (run) {
                e.stopPropagation();
                var file = el.files[0];
                var ext = file["name"].length - 3;
                if (file["name"].toLowerCase().indexOf("tsv") == ext || file["name"].toLowerCase().indexOf("txt") == ext) {
                    var fr = new FileReader();
                    fr.onload = function(e) {
                        $("#gap_values_tsv_input").parent().removeClass("hidden");
                        $("#gap_values_tsv_input").val(e.target.result);
                     }
                     fr.readAsText(file);
                } else
                    alert("Only TSV or TXT files allowed!");
            } else {
                e.preventDefault();
                alert("Sorry! This functionality has yet to be implemented on the backend. Once it has, you will be able to "+
                "use this button to upload a TSV file with terms to complete a query with marked gaps. For instance, given a query:\n\n"+
                "[lemma=~][pos=\"LID.*\"][lemma=~]\n\n"+
                "you would supply a list with two tab-separated columns of terms, where the terms in the first column will be "+
                "entered at the position of the first gap (~) and the words in the second column at the position of the second gap. "+
                "This mimics the batch functionality of the Extended and Advanced search interfaces.\n\n"+
                "Please note that for this to work, you do need to enter a tilde (~) in the field where you want the substitution to take place. "+
                "An empty field will match any term.");
                e.stopPropagation();
            }
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
				} else if (value.match(/^\~$/)) {
					parts.push("["+type+'='+value+']');
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

		parseQueryToInterface : function(pattern, size, group) {
			Whitelab.cql.cqlToNgramsInterface(pattern, size, group);
		},
		
		setTokenInput : function(item, value) {
			Whitelab.debug("Whitelab.explore.ngrams.setTokenInput");
			var f = $(item).data("field");
			var typeValue = $(item).find(":selected").val();
			if (typeValue == "pos")
				$.getScript('/explore/pos/select.js?element_class=field-input&element=%23field-'+f+'&value='+value);
			else
				$("#field-"+f).html('<input class="field-input" type="text">');
		},
		
		submitForm : function() {
			var patt = Whitelab.explore.ngrams.getPatternFromInput();
		    var filterString = Whitelab.metadata.getFilterString();
		    var listType = $("#listtype").val();
		    if (listType.length > 0 && patt.length > 0) {
		    	var selectedTokenCount = $('span.metadata-selected-absolute').data('selected-tokens');
		    	var withinSafeLimit = selectedTokenCount <= Whitelab.metadata.filterTokenSafeLimit;
		    	if ($("#sample_type").val() === "sample" && $("#sample_size").val()) {
		    	    $('#ngrams-input-form #sample').val($("#sample_size").val());
		    	    withinSafeLimit = ($("#sample_size").val() / 100) * selectedTokenCount <= Whitelab.metadata.filterTokenSafeLimit;
		    	} else if ($("#sample_type").val() === "samplenum" && $("#samplenum_size").val()) {
                    $('#ngrams-input-form #samplenum').val($("#samplenum_size").val());
		    	    withinSafeLimit = $("#samplenum_size").val() <= Whitelab.metadata.filterTokenSafeLimit;
		    	}
		    	$('#ngrams-input-form #sampleseed').val($("#seed").val());
		    	if (withinSafeLimit || confirm("You have selected a subcorpus of over "+Whitelab.metadata.filterTokenSafeLimit+" tokens. Please note that this query, on first execution, may take a considerable amount of time to complete. Proceed with caution.\n\nContinue?")) {
		    		$('#ngrams-input-form #patt').val(patt);
			    	$('#ngrams-input-form #filter').val(filterString);
			    	$('#ngrams-input-form #gap_values_tsv').val($("#gap_values_tsv_input").val());
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

		checkSafeLimit : function() {
		    var selectedTokenCount = $('span.metadata-selected-absolute').data('selected-tokens');
            var withinSafeLimit = selectedTokenCount <= Whitelab.metadata.filterTokenSafeLimit;
            if ($("#sample_type").val() === "sample" && $("#sample_size").val().length > 0) {
                $('#statistics-input-form #sample').val($("#sample_size").val());
                withinSafeLimit = ($("#sample_size").val() / 100) * selectedTokenCount <= Whitelab.metadata.filterTokenSafeLimit;
            } else if ($("#sample_type").val() === "samplenum" && $("#samplenum_size").val().length > 0) {
                $('#statistics-input-form #samplenum').val($("#samplenum_size").val());
                withinSafeLimit = $("#samplenum_size").val() <= Whitelab.metadata.filterTokenSafeLimit;
            }
            if (withinSafeLimit || confirm("You have selected a subcorpus of over "+Whitelab.metadata.filterTokenSafeLimit+" tokens. Please note that this query, on first execution, may take a considerable amount of time to complete. Proceed with caution.\n\nContinue?")) {
            $('#statistics-input-form #sampleseed').val($("#seed").val());
                return true;
            }
            return false;
		},
		
		submitForm : function() {
			var filterString = Whitelab.metadata.getFilterString();
		    var listType = $("#listtype").val();
		    if (filterString.length > 0 && listType.length > 0) {
		    	if (Whitelab.explore.statistics.checkSafeLimit()) {
		    		$('#statistics-input-form #filter').val(filterString);
			    	$('#statistics-input-form').submit();
		    	}
		    } else {
		    	if (filterString.length == 0) {
                    if (Whitelab.explore.statistics.checkSafeLimit()) {
                        $('#statistics-input-form #filter').val(filterString);
                        $('#statistics-input-form').submit();
                    } else
    		    		alert("Please define a metadata filter.");
		    	}
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

$(document).on("click", "#main-div[data-namespace=\"explore\"] #history-label button.export", function(e) {
	e.preventDefault();
	window.location = '/explore/export/id/'+$("#result-pane").data("query-id")+'.xml';
});
