Whitelab.search = {
	
	init : function() {
		
		if ($('#metadata-filters').length > 0)
			Whitelab.metadata.init();
		
		if ($("#main-div[data-namespace='search'] #query-details").length > 0) {
			var id = $('#query-details').data("query-id");
			$.getScript('/search/details/id/'+id+'.js');
		}
		
		if ($("#main-div[data-namespace='search'] div#results").length > 0)
			Whitelab.search.result.init();

		if ($('div#expert').length > 0)
			Whitelab.search.expert.init();
		
		if ($('div#advanced').length > 0)
			Whitelab.search.advanced.init();
		
		if ($('div#extended').length > 0)
			Whitelab.search.extended.init();
		
		if ($('div#simple').length > 0)
			Whitelab.search.simple.init();

		if ($("#document-display").length > 0)
			Whitelab.document.init();
		
	},
	
	validateInput : function(url,input,view) {
		Whitelab.debug("validateInput");
		if (view == 1) {
			var inp = $(input).val();
			Whitelab.debug("INPUT: "+inp);
			var cql = Whitelab.cql.simpleQueryStringToCQL(inp, false);
			if (cql && cql !== "") {
				Whitelab.debug("CQL: "+cql);
			}
		}
	},
	
	getQueryResult : function(number,offset) {
		var id = $('div#result-pane').data("query-id");
		$.getScript('/search/result/id/'+id+'.js?number='+number+'&offset='+offset);
	},
	
	operatorToValue : function(op) {
		if (op === '!=')
			return 'not';
		return 'is';
	},
	
	removeQuery : function(queryId) {
		$.getScript('/search/remove/id/'+queryId+'.js');
	},
	
	advanced : {
		
		doDebug : true,
		
		debug : function(msg) {
			if (Whitelab.search.advanced.doDebug)
				Whitelab.debug(msg);
		},
		
		init : function() {

			var input_page = $('#advanced').data('query-input-page');
			if (input_page === 'simple' || input_page === 'extended' || input_page === 'advanced')
				Whitelab.search.advanced.parseQueryToInterface($('#advanced').data('query-pattern'));
			else
				Whitelab.search.advanced.addFieldToBoxInColumn(0, 0);
		},
		
		addColumn : function() {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.addColumn");
			var c = document.getElementsByClassName("advanced-column").length;
			$.getScript('/search/advanced/column.js?column='+c);
		},
		
		addBoxToColumn : function(c) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.addBoxToColumn");
			var b = $("#column"+c).find('div.advanced-box').length;
			$.getScript('/search/advanced/box.js?column='+c+'&box='+b);
		},
		
		addFieldToBoxInColumn : function(b, c, token_type, operator, input, batch, sensitive, startsen, endsen, repeat_from, repeat_to) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.addFieldToBoxInColumn");
			var f = $("#column"+c+"-box"+b).find('div.advanced-field').length;
			var url = '/search/advanced/field.js?column='+c+'&box='+b+'&field='+f;
			if (token_type != null)
				url = url + '&token_type='+token_type;
			if (operator != null)
				url = url + '&operator='+operator;
			if (input != null)
				url = url + '&input='+input;
			if (batch != null)
				url = url + '&batch='+batch;
			if (sensitive != null)
				url = url + '&sensitive='+sensitive;
			if (startsen != null)
				url = url + '&startsen='+startsen;
			if (endsen != null)
				url = url + '&endsen='+endsen;
			if (repeat_from != null)
				url = url + '&repeat_from='+repeat_from;
			if (repeat_to != null)
				url = url + '&repeat_to='+repeat_to;
			$.getScript(url);
		},
		
		removeAllColumns : function() {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.removeAllColumns");
			$("#advanced-canvas").find(".advanced-column").remove();
		},
		
		removeColumn : function(c) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.removeColumn("+c+")");
			if ($(document).find('div.advanced-column').length == 1)
				Whitelab.search.advanced.reset();
			else {
				$("#column"+c).remove();
				Whitelab.search.advanced.resetElementIds();
			}
		},
		
		removeBoxFromColumn : function(b, c) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.removeBoxFromColumn");
			$("#column"+c+"-box"+b).remove();
			var column = document.getElementById("column"+c);
			if ($(column).find(".advanced-box").length == 0)
				Whitelab.search.advanced.removeColumn(c);
			else {
				Whitelab.search.advanced.resetButtonsOnColumn(c);
				Whitelab.search.advanced.resetElementIds();
			}
		},
		
		removeFieldFromBoxInColumn : function(f, b, c) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.removeFieldFromBoxInColumn("+f+","+b+","+c+")");
			$("#column"+c+"-box"+b+"-field"+f).remove();
			var box = document.getElementById("column"+c+"-box"+b);
			if (box.getElementsByClassName("advanced-field").length == 0)
				Whitelab.search.advanced.removeBoxFromColumn(b, c);
			else
				Whitelab.search.advanced.resetElementIds();
		},
		
		reset : function() {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.reset");
			Whitelab.search.advanced.removeAllColumns();
			Whitelab.search.advanced.addColumn();
		},
		
		resetBoxHeader : function(b, c) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.resetBoxHeader");
			var box = document.getElementById("column"+c+"-box"+b);
			if (box.getElementsByClassName('advanced-field').length > 1) {
				$(box).find("div.box-header > div").first().removeClass("hidden");
			} else {
				$(box).find("div.box-header > div").first().addClass("hidden");
			}
		},
		
		resetColumnHeader : function(c) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.resetBoxHeader");
			var column = document.getElementById("column"+c);
			if (document.getElementsByClassName('advanced-column').length > 1) {
				$(column).find("div.close").first().removeClass("hidden");
			} else {
				$(column).find("div.close").first().addClass("hidden");
			}
		},
		
		resetButtonsOnColumn : function(c) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.resetButtonsOnColumn");
			var column = document.getElementById("column"+c);
			if (column.getElementsByClassName('advanced-field').length > 1) {
				$.each(column.getElementsByClassName('advanced-field'), function(i, field) {
					$(field).find('div.field-remove').first().removeClass('hidden');
				});
			} else {
				$.each(column.getElementsByClassName('advanced-field'), function(i, field) {
					$(field).find('div.field-remove').first().addClass('hidden');
				});
			}
		},
		
		resetElementIds : function() {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.resetElementIds");
			var columns = $(document).find('div.advanced-column');
			$.each(columns, function(i, column) {
				$(column).attr('id','column'+i);
				var withData = column.querySelectorAll('[data-column]');
				$.each(withData, function(ii, dataItem) {
					$(dataItem).data('column',i);
				});
				Whitelab.search.advanced.resetColumnHeader(i);
				var boxes = $(column).find('div.advanced-box');
				$.each(boxes, function(j, box) {
					$(box).attr('id','column'+i+'-box'+j);
					Whitelab.search.advanced.resetBoxHeader(j, i);
					var withData = box.querySelectorAll('[data-box]');
					$.each(withData, function(jj, dataItem) {
						$(dataItem).data('box',j);
					});
					$.each($(box).find('div.advanced-field'), function(k, field) {
						$(field).attr('id','column'+i+'-box'+j+'-field'+k);
						var withData = field.querySelectorAll('[data-field]');
						$.each(withData, function(kk, dataItem) {
							$(dataItem).data('field',k);
						});
					});
				});
			});
		},
		
		toggleSettingsOnColumn : function(c) {
			var column = document.getElementById("column"+c);
			$(column.getElementsByClassName("options")[0]).toggleClass("hidden");
		},

		eraseBatchList : function(el) {
			$(el).parent().parent().parent().find(".batchrow").removeClass("active");
			$(el).parent().parent().parent().find(".batchlist").val("");
			$(el).parent().parent().parent().find(".inputrow").addClass("active");
			$(el).parent().parent().parent().find(".loadbutton").html('<div class="batchWordListBtn"><button class="load-small"></button></div><input class="small-loadlist" type="file" onchange="Whitelab.search.advanced.loadBatchList(this);">');
			$("#advanced .splitcheck").prop("checked",false);
		},
		
		loadBatchList : function(el) {
			Whitelab.readFile(el.files[0], function(e) {
		        var text = e.target.result;
		        text.replace(/(\r\n\r\n|\n\n|\r\r)/gm,/\n/);
		        text.trim();
		        var batch = $(el).parent().parent().prev();
		        batch.addClass("active");
		    	batch.find(".batchlist").val(text);
		    	var input = $(el).parent().parent();
		    	input.removeClass("active");
		    });
			
			$("#advanced .splitcheck").prop("checked",true);
		},
		
		setTokenInput : function(item) {
			Whitelab.search.advanced.debug("Whitelab.search.advanced.setTokenInput");
			var row = $(item).parent().parent();
			var c = $(row).find(".token-type").data("column");
			var b = $(row).find(".token-type").data("box");
			var f = $(row).find(".token-type").data("field");
			var typeValue = $(row).find(".token-type").find(":selected").val();
			var operatorValue = $(row).find(".token-operator").find(":selected").val();
			if (typeValue == "pos" && (operatorValue == "is" || operatorValue == "not"))
				$.getScript('/interface/pos/select.js?element_class=advanced-pos-select&element=%23column'+c+'-box'+b+'-field'+f+'%20div.token-input-field');
			else
				$("#column"+c+"-box"+b+"-field"+f+" div.token-input-field").html('<input placeholder="<any>" type="text">');
		},
		
		parseQuery : function() {
			var patt = Whitelab.cql.advancedQueryStringToCQL();
			Whitelab.search.advanced.debug("QUERY: "+patt);
			var filter = Whitelab.metadata.getFilterString();
			Whitelab.search.advanced.debug("FILTER: "+filter);
			var within = $("#within").val();
			window.location = '/search/advanced?patt='+encodeURIComponent(patt)+'&filter='+encodeURIComponent(filter)+'&within='+within+'#results';
		},
		
		///////////////////////////////////////////////////////////////////////////
		
		getBoxValue : function(box,type,op) {
			if (type == 'pos' && (op == 'is' || op == 'not')) {
				var term = $(box).find(".advanced-pos-select").first().val();
				return term;
			} else {
				var term = $(box).find(".token-input-field input").first().val();
				return term;
			}
		},
		
		getBoxValues : function(box) {
			var terms = new Array();
			var val = $(box).find(".batchlist").val();
			var vals = val.split("\n");
			$.each(vals, function(i,v) {
				var term = v.trim();
				if (term.length > 0) {
					terms.push(term);
				}
			});
			return terms;
		},
		
		parseQueryToInterface : function(pattern) {
			Whitelab.cql.cqlToAdvancedInterface(pattern);
		}
	},
	
	expert : {
		
		init : function() {
			
		},
		
		parseQuery : function() {
			var patt = $("#expert-input").val();
			var filter = Whitelab.metadata.getFilterString();
			var within = $("#within").val();
			window.location = '/search/expert?patt='+encodeURIComponent(patt)+'&filter='+encodeURIComponent(filter)+'&within='+within+'#results';
		}
		
	},
	
	extended : {
		
		init : function() {

			var input_page = $('#extended').data('query-input-page');
			if (input_page === 'simple' || input_page === 'extended')
				Whitelab.search.extended.parseQueryToInterface($('#extended').data('query-pattern'));
			
		},
		
		eraseBatchList : function(el) {
			$(el).parent().parent().parent().find(".batchrow").removeClass("active");
			$(el).parent().parent().parent().find(".inputrow").addClass("active");
			$(el).parent().parent().parent().find(".batchlist").html("");
			$(el).parent().parent().parent().find(".file-control").html('<div style="position:relative; height: 36px;"><div class="batchWordListBtn"><button class="load" onclick="event.preventDefault();"></button></div><input class="loadlist" type="file" onchange="Whitelab.search.extended.loadBatchList(this);"></div>');
			$("#extended .splitcheck").prop("checked",false);
		},
		
		loadBatchList : function(el) {
			Whitelab.readFile(el.files[0], function(e) {
		        var text = e.target.result;
		        text.replace(/(\r\n\r\n|\n\n|\r\r)/gm,/\n/);
		        text.trim();
		        var batch = $(el).parent().parent().parent().prev();
		        batch.addClass("active");
		    	batch.find(".batchlist").html(text);
		    	var input = $(el).parent().parent().parent();
		    	input.removeClass("active");
		    });
			$("#extended .splitcheck").prop("checked",true);
		},
		
		parseQuery : function() {
			var patt = Whitelab.cql.extendedQueryStringToCQL();
			var filter = Whitelab.metadata.getFilterString();
			var within = $("#within").val();
			Whitelab.debug("PATTERN: "+patt);
			window.location = '/search/extended?patt='+encodeURIComponent(patt)+'&filter='+encodeURIComponent(filter)+'&within='+within+'#results';
		},
		
		parseQueryToInterface : function(pattern) {
			Whitelab.cql.cqlToExtendedInterface(pattern);
		}
		
	},
	
	result : {
		
		init : function() {
			
			var id = $('div#result-pane').data("query-id");
			$.getScript('/search/result/id/'+id+'.js');
			
		}
		
	},
	
	simple : {
		
		init : function() {

			var input_page = $('#simple').data('query-input-page');
			if (input_page === 'simple')
				$("#simple input#patt").val(Whitelab.cql.cqlToSimpleQueryString($('#simple').data('query-pattern')));
			
		},
		
		parseQuery : function() {
//			Whitelab.debug("PATTERN: "+$("#patt").val());
			var patt = Whitelab.cql.simpleQueryStringToCQL($("#patt").val(), false);
			window.location = '/search/simple?patt='+encodeURIComponent(patt)+'#results';
		}
		
	}
		
};

$(document).on('click', '#advanced a.add-column', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.addColumn();
});

$(document).on('click', '#advanced a.add-box', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.addBoxToColumn($(this).data('column'));
});

$(document).on('click', '#advanced a.add-field', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.addFieldToBoxInColumn($(this).data('box'),$(this).data('column'));
});

$(document).on('click', '#advanced a.remove-column', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.removeColumn($(this).data('column'));
});

$(document).on('click', '#advanced a.remove-field', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.removeFieldFromBoxInColumn($(this).data('field'),$(this).data('box'),$(this).data('column'));
});

$(document).on('click', '#advanced a.toggle-settings', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.toggleSettingsOnColumn($(this).data('column'));
});

$(document).on('click', '#advanced a.repeat', function(e) {
	e.preventDefault();
	var column = document.getElementById("column"+$(this).data('column'));
	$(column).find('div.repeat').first().toggleClass('active');
});

$(document).on('click', '#advanced a.startsen', function(e) {
	e.preventDefault();
	var column = document.getElementById("column"+$(this).data('column'));
	$(column).find('span.startsen').first().toggleClass('active');
});

$(document).on('click', '#advanced a.endsen', function(e) {
	e.preventDefault();
	var column = document.getElementById("column"+$(this).data('column'));
	$(column).find('span.endsen').first().toggleClass('active');
});

$(document).on('change', '#advanced select.token-type', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.setTokenInput(this);
});

$(document).on('change', '#advanced select.token-operator', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.setTokenInput(this);
});

$(document).on('click', '#advanced div.batchrow .erase', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.eraseBatchList(this);
});

$(document).on('change', '#advanced input.small-loadlist', function(e) {
	e.preventDefault();
	Whitelab.search.advanced.loadBatchList(this);
});

$(document).on('click', '#advanced button.btn-submit', function(e) {
	e.preventDefault();
	Whitelab.debug('FORM CLICK ADVANCED');
	Whitelab.search.advanced.parseQuery();
});

$(document).keypress(function(e) {
	if (e.which == 13) {
		if ($("#advanced").length > 0)
			Whitelab.search.advanced.parseQuery();
		if ($("#extended").length > 0)
			Whitelab.search.extended.parseQuery();
		if ($("#expert").length > 0)
			Whitelab.search.expert.parseQuery();
		if ($("#simple").length > 0)
			Whitelab.search.simple.parseQuery();
	}
});

$(document).on('click', '#expert button.btn-submit', function(e) {
	e.preventDefault();
	Whitelab.debug('FORM CLICK EXPERT');
	Whitelab.search.expert.parseQuery();
});

$(document).on('click', '#expert a.expert-info-icon', function(e) {
	e.preventDefault();
    e.stopPropagation();
	$('.expert-info').toggleClass('active');
});

$(document).on('click', '#extended button.btn-submit', function(e) {
	e.preventDefault();
	Whitelab.debug('FORM CLICK EXTENDED');
	Whitelab.search.extended.parseQuery();
});

$(document).on('click', '#main-div[data-namespace="search"] button.show-document', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var docpid = $(this).data("docpid");
	var qid = $("#result-pane").data("query-id");
	window.location = '/search/document/'+docpid+'/query/'+qid;
});

$(document).on('change', '#main-div[data-namespace="search"] select.group-by-select', function(e) {
	var group = $(this).val();
	if (group != null && group.length > 0) {
		var page = $("#result-pane").data('query-page');
		window.location = '/search/'+page+'?'+Whitelab.assembleQueryParams({
			'patt': $("#result-pane").data('query-patt'), 
			'filter': $("#result-pane").data('query-filter'), 
			'within': $("#result-pane").data('query-within'), 
			'view': $("#result-pane").data('query-view'), 
			'group': group, 
			'offset': 0, 
			'number': 50
		});
	}
});

$(document).on('click', '#main-div[data-namespace="search"] tr.hit-row', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var docpid = $(this).data("docpid");
	var f = $(this).data("first-index");
	var l = $(this).data("last-index");
	if ($("#"+docpid+"_"+f+"_"+l).html().length == 0) {
		$("#"+docpid+"_"+f+"_"+l).html('<span class="loading"></span>');
		$.getScript('/search/kwic.js?docpid='+docpid+'&first_index='+f+'&last_index='+l+'&size=50');
	}
	$("#"+docpid+"_"+f+"_"+l).toggleClass("hidden");
});

$(document).on('click', '#main-div[data-namespace="search"] tr.doc-row', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var docpid = $(this).data("docpid");
	var hits = $(this).data("hits");
	var qid = $("#result-pane").data("query-id");
	if ($("#"+docpid).html().length == 0) {
		$("#"+docpid).html('<span class="loading"></span>');
		$.getScript('/search/doc_hits/id/'+qid+'.js?view=1&docpid='+docpid+'&hits='+hits);
	}
	$("#"+docpid).toggleClass("hidden");
});

$(document).on('click', '#simple button.btn-submit', function(e) {
	Whitelab.debug('FORM CLICK SIMPLE');
	e.preventDefault();
	e.stopPropagation();
	Whitelab.search.simple.parseQuery();
});

$(document).on('change', 'div.search-input-display input, div.search-input-display select', function(e) {
	var func = $("#main-div[data-namespace='search'] div.search-input-display").attr("id")+"QueryStringToCQL";
	var patt = window["Whitelab"]["cql"][func]();
	$('.tablink').each(function(i, item) {
		$(item).attr('data-patt', patt);
	});
});

$(document).on('click', '#main-div[data-namespace="search"] a.tablink', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var url = "/search/"+$(this).data('page');
	var params = $(this).data("params");
	var patt = $(this).data("patt");
	if (params.length > 0)
		url = url+"?"+params;
	if (patt.length > 0)
		if (params.length > 0)
			url = url+"&patt="+patt;
		else
			url = url+"?patt="+patt;
		
	window.location = url;
});
