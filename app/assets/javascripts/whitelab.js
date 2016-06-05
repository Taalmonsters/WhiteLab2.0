var Whitelab = {
	namespace : 'search',
	doDebug : false,
	
	debug : function(msg) {
		if (Whitelab.doDebug)
			console.log(msg);
	},
	
	init : function() {
		
		Whitelab.help.init();
		
		if ($("#main-div[data-namespace='admin']").length > 0) {
			Whitelab.namespace = 'admin';
			Whitelab.admin.init();
		}
		
		if ($("#main-div[data-namespace='explore']").length > 0) {
			Whitelab.namespace = 'explore';
			Whitelab.explore.init();
		}
		
		if ($("#main-div[data-namespace='search']").length > 0) {
			Whitelab.namespace = 'search';
			Whitelab.search.init();
		}

		if ($('#query-list').length > 0)
			Whitelab.history.init();
		
		if ($('form #submit-group').length > 0) {
			$(document).on('click', '#submit-group button.submit', function(e) {
				e.preventDefault();
				e.stopPropagation();
				$(this).parent().parent().submit();
				return false;
			});
		}
		
		if ($('a.vis-toggle').length > 0) {
			$(document).on('click', 'a.vis-toggle', function(e) {
				e.preventDefault();
				var id = $(this).data("toggle-id");
				$('#'+id).toggleClass("hidden");
				if ($('#'+id).hasClass("hidden"))
					$(this).html($(this).data("label-show"));
				else
					$(this).html($(this).data("label-hide"));
			});
		}
		
		if (Whitelab.tour.active) {
			Whitelab.tour.init();
		}
		
		Whitelab.layout.resize();
		
	},
	
	assembleQueryParams : function(data) {
		Whitelab.debug("assembleQueryParams");
		Whitelab.debug(data);
		var params = [];
		var keys = ['patt', 'filter', 'within', 'view', 'group', 'offset', 'number'];
		for (var k = 0; k < keys.length; k++) {
			if (keys[k] in data && data[keys[k]] != null && data[keys[k]].length > 0) {
				params.push(keys[k]+'='+encodeURIComponent(data[keys[k]]));
			}
		}
		return params.join('&');
	},
	
	createRequest : function(method, url) {
		var xhr = new XMLHttpRequest();
		if ("withCredentials" in xhr) {
			// XHR for Chrome/Firefox/Opera/Safari.
			xhr.open(method, url, true);
		} else if (typeof XDomainRequest != "undefined") {
			// XDomainRequest for IE.
			xhr = new XDomainRequest();
			xhr.open(method, url);
		} else {
			// CORS not supported.
			xhr = null;
		}
		return xhr;
	},
	
	debugXhrResponse : function(msg) {
		if (Whitelab.doDebug) {
			console.log(msg);
		}
	},
	
	getHtmlData : function(url, params, target, callback) {
		
		$.ajax({
            url: url, // Route to the Script Controller method
           type: "GET",
       dataType: "json",
           data: params, // This goes to Controller in params hash, i.e. params[:file_name]
       complete: function() {
					callback();
       			 },
        success: function(data, textStatus, xhr) {
		    	   	$(target).html(data.html);
                 },
          error: function() {
        	  		$(target).html("Ajax error!");
                 }
		});
	},

	getListPage : function(id,u,n,f,s,o) {
		var url = $(id).data('url');
		if (u != null)
			url = u;
		var number = $(id).data('number');
		if (n != null)
			number = n;
		var offset = $(id).data('offset');
		if (f != null)
			offset = f;
		var sort = $(id).data('sort');
		if (s != null)
			sort = s;
		var order = $(id).data('order');
		if (o != null)
			order = o;
		if (url.indexOf('?') > -1)
			return url+"&number="+number+"&offset="+offset+"&sort="+sort+"&order="+order;
		else
			return url+"?number="+number+"&offset="+offset+"&sort="+sort+"&order="+order;
	},
	
	goToPage : function(url) {
		Whitelab.debug("goToPage");
		window.location = url;
	},

	loadGroupedDocs : function(group_id,group_value) {
		var qid = $("#result-pane").data("query-id");
		var o = $("#"+group_id).data("offset");
		group_value = encodeURIComponent(group_value);
		if ($("#main-div[data-namespace='search']").length > 0)
			$.getScript('/search/result/id/'+qid+'/groupdocs.js?group_id='+group_id+'&docs_group='+group_value+'&offset='+o+'&number=20');
		else if ($("#main-div[data-namespace='explore']").length > 0)
			$.getScript('/explore/result/id/'+qid+'/groupdocs.js?group_id='+group_id+'&docs_group='+group_value+'&offset='+o+'&number=20');
	},
	
	loadGroupedHits : function(group_id,group_value) {
		Whitelab.debug("loadGroupedHits");
		group_value = encodeURIComponent(group_value);
		var qid = $("#result-pane").data("query-id");
		var o = $("#"+group_id).data("offset");
		if ($("#main-div[data-namespace='search']").length > 0)
			$.getScript('/search/result/id/'+qid+'/grouphits.js?group_id='+group_id+'&hits_group='+group_value+'&offset='+o+'&number=20');
		else if ($("#main-div[data-namespace='explore']").length > 0)
			$.getScript('/explore/result/id/'+qid+'/grouphits.js?group_id='+group_id+'&hits_group='+group_value+'&offset='+o+'&number=20');
	},
	
	readFile : function(f, callback) {
		if (!f) {
	        alert("Failed to load file");
	    } else if (!f.type.match('text.*')) {
			    alert(f.name + " is not a valid text file.");
	    } else {
	    	var reader = new FileReader();
	        reader.onload = callback;
	        reader.readAsText(f);
	    }
	},
	
	setLanguage : function(url,lang) {
		if (url.indexOf('locale') > -1) {
			url = url.replace(/[\?\&]locale=[a-z]{2}/, "");
		}
		if (url.indexOf('?') > -1) {
			window.location = url+'&locale='+lang;
		} else {
			window.location = url+'?locale='+lang;
		}
	},

	showGroupedDocs : function(group_value) {
		Whitelab.debug("showGroupedDocs");
		var patt = $("#query-details td.patt").html();
		var within = $("#query-details td.within").html();
		var filter = $("#query-details td.filter").html();
		if (typeof filter === 'undefined')
			filter = '';
		var group = $("#query-details td.group").html();
		if (group.indexOf("hit_") > -1) {
			group_value = encodeURIComponent(group_value);
			patt = "[word=\"(?c)"+group_value+"\"]";
		} else if (group.indexOf("_left") > -1) {
			group_value = encodeURIComponent(group_value);
			if (group.indexOf("lemma_") > -1)
				patt = "[lemma=\"(?c)"+group_value+"\"]"+patt;
			else if (group.indexOf("pos_") > -1)
				patt = "[pos=\""+group_value+"\"]"+patt;
			else if (group.indexOf("phonetic_") > -1)
				patt = "[phonetic=\"(?c)"+group_value+"\"]"+patt;
			else
				patt = "[word=\"(?c)"+group_value+"\"]"+patt;
		} else if (group.indexOf("_right") > -1) {
			group_value = encodeURIComponent(group_value);
			if (group.indexOf("lemma_") > -1)
				patt = patt+"[lemma=\"(?c)"+group_value+"\"]";
			else if (group.indexOf("pos_") > -1)
				patt = patt+"[pos=\"(?c)"+group_value+"\"]";
			else if (group.indexOf("phonetic_") > -1)
				patt = patt+"[phonetic=\"(?c)"+group_value+"\"]";
			else
				patt = patt+"[word=\"(?c)"+group_value+"\"]";
		} else {
			if (filter.length > 0)
				filter = filter+"AND("+group+"="+"\""+group_value+"\")";
			else
				filter = "("+group+"="+"\""+group_value+"\")";
		}
		window.location = "/search/expert?view=2&patt="+patt+"&within="+within+"&filter="+filter;
	},

	showGroupedHits : function(group_value) {
		Whitelab.debug("showGroupedHits");
		var patt = $("#query-details td.patt").html();
		var within = $("#query-details td.within").html();
		var filter = $("#query-details td.filter").html();
		if (typeof filter === 'undefined')
			filter = '';
		var group = $("#query-details td.group").html();
		if (group.indexOf("hit_") > -1) {
			group_value = encodeURIComponent(group_value);
			patt = "[word=\"(?c)"+group_value+"\"]";
		} else if (group.indexOf("_left") > -1) {
			group_value = encodeURIComponent(group_value);
			if (group.indexOf("lemma_") > -1)
				patt = "[lemma=\"(?c)"+group_value+"\"]"+patt;
			else if (group.indexOf("pos_") > -1)
				patt = "[pos=\""+group_value+"\"]"+patt;
			else if (group.indexOf("phonetic_") > -1)
				patt = "[phonetic=\"(?c)"+group_value+"\"]"+patt;
			else
				patt = "[word=\"(?c)"+group_value+"\"]"+patt;
		} else if (group.indexOf("_right") > -1) {
			group_value = encodeURIComponent(group_value);
			if (group.indexOf("lemma_") > -1)
				patt = patt+"[lemma=\"(?c)"+group_value+"\"]";
			else if (group.indexOf("pos_") > -1)
				patt = patt+"[pos=\"(?c)"+group_value+"\"]";
			else if (group.indexOf("phonetic_") > -1)
				patt = patt+"[phonetic=\"(?c)"+group_value+"\"]";
			else
				patt = patt+"[word=\"(?c)"+group_value+"\"]";
		} else {
			if (filter.length > 0)
				filter = filter+"AND("+group+"="+"\""+group_value+"\")";
			else
				filter = "("+group+"="+"\""+group_value+"\")";
		}
		window.location = "/search/expert?view=1&patt="+patt+"&within="+within+"&filter="+filter;
	},
	
	sleep : function(ms) {
		var start = new Date().getTime();
		for (var i = 0; i < 1e7; i++) {
			if ((new Date().getTime() - start) > ms) {
				break;
			}
		}
	},
	
	help : {
		dialog : null,
		
		init : function() {
			
			Whitelab.help.dialog = $( "#help-dialog" ).dialog({
				closeOnEscape: true,
				draggable: true,
				autoOpen: false,
				width: 400,
				height: 150,
				modal: true,
				resizable: false,
				buttons: {
				},
				close: function() {
					$('#help-dialog').dialog('option', 'title', 'Loading...');
					$('#help-content').html('<span class="loading"></span>');
				}
			});
			
			$(document).on('click', '#help-icon', function(e) {
				e.preventDefault();
				e.stopPropagation();
				Whitelab.help.dialog.dialog( "open" );
				$.getScript('/help');
			});
			
		}
		
	},
	
	history : {
		dialog : null,
		
		init : function() {
			
			Whitelab.history.dialog = $( "#history-dialog" ).dialog({
				closeOnEscape: true,
				draggable: true,
				autoOpen: false,
				width: 850,
				minHeight: 300,
				modal: true,
				resizable: false,
				buttons: {
				},
				close: function() {
					$('#history-dialog').dialog('option', 'title', 'Loading...');
					$('#query-list').html('<span class="loading"></span>');
				}
			});
			
		},
		
		loadQueryList : function(l,el) {
			if (Whitelab.namespace === 'search') {
				var id = $('#query-list').find("table.query-table").first().data("current-query-id");
				if (id != null && id.length > 0)
					$.getScript('/search/history/id/'+id+'.js?qllimit='+l+'&eqllimit='+el);
				else
					$.getScript('/search/history.js?qllimit='+l+'&eqllimit='+el);
			} else {
				$.getScript('/'+Whitelab.namespace+'/history.js?qllimit='+l+'&eqllimit='+el);
			}
		}
		
	}
	
};

$(document).on('click', 'a.langlink', function(e) {
	e.preventDefault();
	Whitelab.setLanguage($(this).data('url'),$(this).data('language'));
});

$(document).on('click', 'a.sort-header', function(e) {
	e.preventDefault();
	var url = $(this).parent().parent().parent().parent().data('url');
	var sort = $(this).data('sort-key');
	var order = $(this).data('sort-order');
	var id = '#'+$("div.page-list-main").attr('id');
	window.location = Whitelab.getListPage(id,url,null,null,sort,order);
});

$(document).on('click', '.btn-export', function(e) {
	e.preventDefault();
	e.stopPropagation();
	if (Whitelab.namespace === 'explore' || Whitelab.namespace === 'search') {
		var queryId = $(this).data("query-id");
		$.getScript('/data/export/id/'+queryId+'.js?namespace='+Whitelab.namespace);
	}
});

$(document).on('click', '.btn-reset', function(e) {
	e.preventDefault();
	window.location = $(this).data("url");
});

$(document).on('click', 'button.btn-pagination', function(e) {
	if ($("#main-div[data-namespace='search'] div#result-pane").length > 0)
		Whitelab.search.getQueryResult($(this).data("number"),$(this).data("offset"));
	else if ($("#main-div[data-namespace='explore'] div#result-pane").length > 0)
		Whitelab.explore.getQueryResult($(this).data("number"),$(this).data("offset"));
	else if ($("#document-display").length > 0)
		Whitelab.document.loadDocument($("#document-display").data("tab"), $("#document-display").data("xmlid"), $("#document-display").data("query-id"),$(this).data("offset"),$(this).data("number"));
	else
		window.location = Whitelab.getListPage('#'+$("div.page-list-main").attr('id'),$("div.page-list-main").data('url'),$(this).data("number"),$(this).data("offset"),null,null);
});

$(document).on('click', 'button.load-grouped-docs', function(e) {
	var group_id = $(this).data("group-id");
	var group_value = $(this).data("group-value");
	Whitelab.loadGroupedDocs(group_id,group_value);
});

$(document).on('click', 'button.load-grouped-hits', function(e) {
	var group_id = $(this).data("group-id");
	var group_value = $(this).data("group-value");
	Whitelab.loadGroupedHits(group_id,group_value);
});

$(document).on('click', 'button.show-grouped-docs', function(e) {
	var group_value = $(this).data("group-value");
	Whitelab.showGroupedDocs(group_value);
});

$(document).on('click', 'button.show-grouped-hits', function(e) {
	var group_value = $(this).data("group-value");
	Whitelab.showGroupedHits(group_value);
});

$(document).on('click', '.info-panel-toggle', function(e) {
	e.preventDefault();
	if ($(this).parent().find('div.panel-info').length > 0)
		$(this).parent().find('div.panel-info').toggleClass('hidden');
	else if ($(this).parent().parent().find('div.panel-info').length > 0)
		$(this).parent().parent().find('div.panel-info').toggleClass('hidden');
});

$(document).on('change', 'input[type="text"].alphanumeric-only', function(e) {
	var val = $(this).val();
	if (/[^a-zA-Z0-9]/.test(val)) {
		$(this).parent().find('div.panel-error').removeClass('hidden');
	} else {
		$(this).parent().find('div.panel-error').addClass('hidden');
	}
});

$(document).on('change', 'select.lang-select', function(e) {
	var url = $(this).parent().data('url');
	Whitelab.setLanguage($(this).parent().data('url'),$(this).val());
});

$(document).on('change', 'select.pagination-size-select', function(e) {
	if ($("#main-div[data-namespace='search'] div#result-pane").length > 0)
		Whitelab.search.getQueryResult($(this).val(),0);
	else if ($("#main-div[data-namespace='explore'] div#result-pane").length > 0)
		Whitelab.explore.getQueryResult($(this).val(),0);
	else
		window.location = Whitelab.getListPage('#'+$("div.page-list-main").attr('id'),$("div.page-list-main").data('url'),$(this).val(),0,null,null);
});

$(document).on('change', 'select.pagination-go-to', function(e) {
	var n = $(this).data('number');
	var o = ($(this).val() - 1) * n;
	if ($("#main-div[data-namespace='search'] div#result-pane").length > 0)
		Whitelab.search.getQueryResult(n,o);
	else if ($("#main-div[data-namespace='explore'] div#result-pane").length > 0)
		Whitelab.explore.getQueryResult(n,o);
	else if ($("#document-display").length > 0)
		Whitelab.document.loadDocument($("#document-display").data("tab"), $("#document-display").data("xmlid"), $("#document-display").data("query-id"),o,n);
	else
		window.location = Whitelab.getListPage('#'+$("div.page-list-main").attr('id'),$("div.page-list-main").data('url'),n,o,null,null);
});

$(document).on('click', 'tr.grouped-hit-row', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var group_id = $(this).data("group-id");
	var group_value = $(this).data("group-value");
	if ($("#"+group_id+" div.hits > table > tbody").html().length == 0) {
		Whitelab.loadGroupedHits(group_id,group_value);
	}
	$("#"+group_id).toggleClass("hidden");
});

$(document).on('click', 'tr.grouped-doc-row', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var group_id = $(this).data("group-id");
	var group_value = $(this).data("group-value");
	if ($("#"+group_id+" div.docs > table > tbody").html().length == 0) {
		Whitelab.loadGroupedDocs(group_id,group_value);
	}
	$("#"+group_id).toggleClass("hidden");
});

$(document).on('click', 'ul.nav.active-tabs > li > a', function(e) {
	e.preventDefault();
	$(this).parent().parent().find("li").removeClass("active");
	$(this).parent().addClass("active");
	var link = $(this).attr('href');
	$(link).parent().find("div.tab-content").addClass("hidden");
	$(link).removeClass("hidden");
});

$(document).on( "click", "a.show-history", function(e) {
	e.preventDefault();
	Whitelab.history.dialog.dialog( "open" );
	Whitelab.history.loadQueryList(5,5);
});


$(document).on('click', 'div#query-list tr.clickable', function(e) {
	e.preventDefault();
	var id = $(this).data("query-id");
	var page = $(this).data("query-view-page");
	var ns = $(this).data("namespace");
	window.location = '/'+ns+'/'+page+'?'+Whitelab.assembleQueryParams({
		'patt': $(this).find("td.patt").first().data('patt'), 
		'filter': $(this).find("td.filter").first().data('filter'), 
		'within': $(this).find("td.within").first().data('within'), 
		'view': $(this).data("view"), 
		'group': $(this).find("td.group").first().data('group'), 
		'offset': $(this).data("offset"), 
		'number': $(this).data("number")
	});
});

$(document).on('click', 'a.remove-query', function(e) {
	e.preventDefault();
	e.stopPropagation();
	Whitelab.search.removeQuery($(this).data('query-id'));
});

$(document).on('click', 'a.download-result', function(e) {
	e.preventDefault();
	e.stopPropagation();
	window.location = '/data/export/id/'+$(this).data('export-query-id')+'/download?format='+$(this).data('format');
});

$(document).on('click', '#load-more-queries', function(e) {
	e.preventDefault();
	var l = $(this).parent().find("table.query-table").first().data("query-history-limit") + 5;
	var el = $(this).parent().find("table.export-query-table").first().data("export-query-history-limit");
	Whitelab.history.loadQueryList(l,el);
});

$(document).on('click', '#load-more-export-queries', function(e) {
	e.preventDefault();
	var l = $(this).parent().find("table.query-table").first().data("query-history-limit");
	var el = $(this).parent().find("table.export-query-table").first().data("export-query-history-limit") + 5;
	Whitelab.history.loadQueryList(l,el);
});
