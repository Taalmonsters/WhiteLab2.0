Whitelab.document = {
	
	init : function() {
		Whitelab.document.loadDocument($("#main-div").data("namespace"), $("#document-display").data("tab"), $("#document-display").data("xmlid"), $("#document-display").data("query-id"));
	},
	
	loadDocument : function(namespace, tab, xmlid, qid, offset, number) {
		Whitelab.debug('QID: '+qid);
		if (tab === '')
			tab = 'content';
		if (tab === 'content' && offset == null)
			offset = 0;
		if (tab === 'content' && number == null)
			number = 50;
		if (tab === 'content') {
			if (qid != null && qid !== '') {
				Whitelab.debug('A: /'+namespace+'/document/'+xmlid+'/query/'+qid+'/'+tab+'.js?offset='+offset+'&number='+number);
				$.getScript('/'+namespace+'/document/'+xmlid+'/query/'+qid+'/'+tab+'.js?offset='+offset+'&number='+number);
			} else {
				Whitelab.debug('B: /'+namespace+'/document/'+xmlid+'/'+tab+'.js?offset='+offset+'&number='+number);
				$.getScript('/'+namespace+'/document/'+xmlid+'/'+tab+'.js?offset='+offset+'&number='+number);
			}
		} else {
			if (qid != null && qid !== '') {
				Whitelab.debug('C: /'+namespace+'/document/'+xmlid+'/query/'+qid+'/'+tab+'.js');
				$.getScript('/'+namespace+'/document/'+xmlid+'/query/'+qid+'/'+tab+'.js');
			} else {
				Whitelab.debug('ddddD: /'+namespace+'/document/'+xmlid+'/'+tab+'.js');
				$.getScript('/'+namespace+'/document/'+xmlid+'/'+tab+'.js');
			}
		}
	}
	
};

$(document).on('click', 'a.document-tab', function(e) {
	e.preventDefault();
	if (!$(this).parent().hasClass("active")) {
		$(this).parent().parent().find("li.active").first().removeClass("active");
		$(this).parent().addClass("active");
		var tab = $(this).data("tab");
		if (tab === "statistics")
			$("#document-display div.tab-content").html('<span class="loading"></span> Note: If this page does not load, please disable your ad blocking software.');
		else
			$("#document-display div.tab-content").html('<span class="loading"></span>');
		Whitelab.document.loadDocument($("#main-div").data("namespace"),tab, $("#document-display").data("xmlid"), $("#document-display").data("query-id"));
	}
});

$(document).on('mouseover', '#document-content span.t > a', function(e) {
	e.preventDefault();
	$(this).parent().parent().find('span.hoverdiv').first().addClass('active');
	var ww = $(window).innerWidth()-40;
	var w = $(this).parent().parent().find('span.hoverdiv').first().width();
	var l = $(this).parent().parent().offset().left + 15;
	var r = l+w;
	if (r > ww) {
		l = l - (r - ww) - $(this).parent().parent().offset().left - 15;
		$(this).parent().parent().find('span.hoverdiv').first().css({left: l});
	}
});

$(document).on('mouseout', '#document-content span.t > a', function(e) {
	e.preventDefault();
	$(this).parent().parent().find('span.hoverdiv').first().removeClass('active');
});
