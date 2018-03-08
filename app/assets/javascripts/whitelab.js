// JN 2017-10-31
// Scripts use this to get the base URL.
// This is a quick fix without knowing the ins and outs of Rails.
// There is almost certainly a better, more 'Railsy' way to
// achieve this.
// NOTE: config/application.rb also contains a copy of this value,
//       and the vhost file refers to it as well for Passenger.
var BASE_PATH = '';   // e.g. set this to '/opensonar_whitelab' when mounting application on that URL

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
		
		if (Whitelab.tour.active) {
			Whitelab.tour.init();
		}
		
		Whitelab.layout.resize();

	},
	
	assembleQueryParams : function(data) {
		Whitelab.debug("assembleQueryParams");
		Whitelab.debug(data);
		var params = [];
		var keys = ['patt', 'gap_values_tsv', 'filter', 'within', 'view', 'group', 'offset', 'number', 'sample', 'samplenum', 'sampleseed'];
		for (var k = 0; k < keys.length; k++) {
			if (keys[k] in data && data[keys[k]] != null && data[keys[k]].length > 0) {
				params.push(keys[k]+'='+encodeURIComponent(data[keys[k]]));
			}
		}
		return params.join('&');
	},
	
	checkContextSizeValues : function(one, other, reverse) {
		var x = $(one).val();
		var y = $(other).val();
		if ((reverse && x < y) || (!reverse && x > y)) {
			$(other).val(x);
		}
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
			return url+"&number="+number+"&offset="+offset+"&sort="+sort+"&order="+order+"#results";
		else
			return url+"?number="+number+"&offset="+offset+"&sort="+sort+"&order="+order+"#results";
	},
	
//	goToPage : function(url) {
//		Whitelab.debug("goToPage");
//		window.location = url;
//	},

	loadGroupedDocs : function(group_id,group_value) {
		Whitelab.loadGroupedResults(group_id,group_value,"docs");
	},
	
	loadGroupedHits : function(group_id,group_value) {
		Whitelab.loadGroupedResults(group_id,group_value,"hits");
	},

	loadGroupedResults : function(group_id,group_value,type) {
	    var qid = $("#result-pane").data("query-id");
        var o = $("#"+group_id).data("offset");
		group_value = encodeURIComponent(group_value.replace(/\./g,'\\.'));
        $.getScript(BASE_PATH + '/'+$("#main-div").data("namespace")+'/result/id/'+qid+'/group'+type+'.js?group_id='+group_id+'&'+type+'_group='+group_value+'&offset='+o+'&number=20');
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
		Whitelab.showGroupedResults(group_value,2);
	},

	showGroupedHits : function(group_value) {
		Whitelab.showGroupedResults(group_value,1);
	},

	showGroupedResults : function(group_value, view) {
	    var patt = $("#query-details td.patt").html();
        var within = $("#query-details td.within").html();
        var filter = $("#query-details td.filter").html();
        if (typeof filter === 'undefined')
            filter = '';
        var group = $("#query-details td.group").html().replace(/;/g,'%3B');
//        if (group.indexOf("hit") == -1 && group.indexOf("wordleft") == -1 && group.indexOf("wordright") == -1 && group.indexOf("context") == -1) {
//            if (filter.length > 0)
//                filter = filter+"AND("+group+"="+"\""+group_value+"\")";
//            else
//                filter = "("+group+"="+"\""+group_value+"\")";
//        }
		var sample = $("#query-details").find("td.samplesize > span.sample").first().html();
        if (typeof sample === 'undefined')
            sample = '';
		var samplenum = $("#query-details").find("td.samplesize > span.samplenum").first().html();
        if (typeof samplenum === 'undefined')
            samplenum = '';
	    var sampleseed = $("#query-details").find("td.sampleseed").first().html();
        if (typeof sampleseed === 'undefined')
            sampleseed = '';
        window.location = BASE_PATH + "/search/expert?view="+view+"&patt="+patt+"&within="+within+"&filter="+filter+"&group="+group+"&viewgroup="+group_value+"&sample="+sample+"&samplenum="+samplenum+"&sampleseed="+sampleseed+"#results";
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
				$.getScript(BASE_PATH + '/help');
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
				width: $("body").innerWidth() - 200,
				minHeight: $("body").innerHeight() - 200,
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
		
		loadQueryList : function(sl,el) {
			var ns = $("#main-div").data("namespace");
			var id = $('#query-list').find("table."+ns+"-query-table").first().data("current-query-id");
			if (id != null && id.length > 0)
				$.getScript(BASE_PATH + '/'+ns+'/history/id/'+id+'.js?sl='+sl+'&el='+el);
			else
				$.getScript(BASE_PATH + '/'+ns+'/history.js?sl='+sl+'&el='+el);
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
		Whitelab.document.loadDocument($("#main-div").data("namespace"),$("#document-display").data("tab"), $("#document-display").data("xmlid"), $("#document-display").data("query-id"),$(this).data("offset"),$(this).data("number"));
	else
		window.location = Whitelab.getListPage('#'+$("div.page-list-main").attr('id'),$("div.page-list-main").data('url'),$(this).data("number"),$(this).data("offset"),null,null);
});

$(document).on('click', 'button.load-grouped-docs', function(e) {
	var group_id = $(this).data("group-id");
	var group_value = $(this).data("group-identity");
	Whitelab.loadGroupedDocs(group_id,group_value);
});

$(document).on('click', 'button.load-grouped-hits', function(e) {
	var group_id = $(this).data("group-id");
	var identity = $(this).data("group-identity");
	Whitelab.loadGroupedHits(group_id,identity);
});

$(document).on('click', 'button.show-grouped-docs', function(e) {
	Whitelab.showGroupedDocs($(this).data("group-identity"));
});

$(document).on('click', 'button.show-grouped-hits', function(e) {
	Whitelab.showGroupedHits($(this).data("group-identity"));
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
		window.location = $(this).data("url")+'&offset=0&number='+$(this).val()+'#results';
	else if ($("#main-div[data-namespace='explore'] div#result-pane").length > 0)
		window.location = $(this).data("url")+'&offset=0&number='+$(this).val()+'#results';
	else
		window.location = Whitelab.getListPage('#'+$("div.page-list-main").attr('id'),$("div.page-list-main").data('url'),$(this).val(),0,null,null);
});

$(document).on('change', '.pagination-go-to', function(e) {
	var n = $(this).data('number');
	var o = ($(this).val() - 1) * n;
	if ($("#main-div[data-namespace='search'] div#result-pane").length > 0)
		window.location = $(this).data("url")+'&offset='+o+'&number='+n+'#results';
	else if ($("#main-div[data-namespace='explore'] div#result-pane").length > 0)
		window.location = $(this).data("url")+'&offset='+o+'&number='+n+'#results';
	else if ($("#document-display").length > 0)
		Whitelab.document.loadDocument($("#main-div").data("namespace"),$("#document-display").data("tab"), $("#document-display").data("xmlid"), $("#document-display").data("query-id"),o,n);
	else
		window.location = Whitelab.getListPage('#'+$("div.page-list-main").attr('id'),$("div.page-list-main").data('url'),n,o,null,null);
});

$(document).on('click', 'tr.grouped-hit-row', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var group_id = $(this).data("group-id");
	var identity = $(this).data("group-identity");
	if ($("#"+group_id+" div.hits > table > tbody").html().length == 0) {
		Whitelab.loadGroupedHits(group_id,identity);
	}
	$("#"+group_id).toggleClass("hidden");
});

$(document).on('click', 'tr.grouped-doc-row', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var group_id = $(this).data("group-id");
	var identity = $(this).data("group-identity");
	if ($("#"+group_id+" div.docs > table > tbody").html().length == 0) {
		Whitelab.loadGroupedDocs(group_id,identity);
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

$(document).on( "click", "a.download", function(e) {
	e.stopPropagation();
});


$(document).on('click', 'div#query-list tr.clickable', function(e) {
	e.preventDefault();
	window.location = $(this).data("url")+"#results";
});

$(document).on('click', 'a.remove-query', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var ns = $(this).parent().parent().data("namespace");
	if (ns === 'search')
		Whitelab.search.removeQuery($(this).data('query-id'));
	if (ns === 'explore')
		Whitelab.explore.removeQuery($(this).data('query-id'));
});

$(document).on('click', 'a.export', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var ns = $(this).data("namespace");
	var queryId = $(this).data("query-id");
	$.getScript(BASE_PATH + '/'+ns+'/export/id/'+queryId+'.js');
});

$(document).on('click', '#load-more-search-queries', function(e) {
	e.preventDefault();
	var sl = $(this).parent().find("table.search-query-table").first().data("search-query-history-limit") + 5;
	var el = $(this).parent().find("table.explore-query-table").first().data("explore-query-history-limit") || 5;
	Whitelab.history.loadQueryList(sl,el);
});

$(document).on('click', '#load-more-explore-queries', function(e) {
	e.preventDefault();
	var sl = $(this).parent().find("table.search-query-table").first().data("search-query-history-limit") || 5;
	var el = $(this).parent().find("table.explore-query-table").first().data("explore-query-history-limit") + 5;
	Whitelab.history.loadQueryList(sl,el);
});

$(document).on('click', '#submit-group button.submit', function(e) {
	e.preventDefault();
	e.stopPropagation();
	$(this).parent().parent().submit();
	return false;
});

$(document).on('click', 'a.vis-toggle', function(e) {
	e.preventDefault();
	var id = $(this).data("toggle-id");
	$('#'+id).toggleClass("hidden");
	if ($('#'+id).hasClass("hidden"))
		$(this).html($(this).data("label-show"));
	else
		$(this).html($(this).data("label-hide"));
});

$(document).on('click', '#result-pane ul.nav-tabs a', function(e) {
	e.preventDefault();
	e.stopPropagation();
	var ns = $("#main-div").data("namespace");
	var page = $("div."+ns+"-input-display").attr("id");
	window.location = BASE_PATH + "/"+ns+"/"+page+"?"+$(this).data("params")+"#results";
});

$(document).on('click', '#info a', function(e) {
	e.preventDefault();
	window.open($(this).attr('href').replace(/"/g,''));
});
