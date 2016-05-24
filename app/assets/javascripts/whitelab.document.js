Whitelab.document = {
	
	init : function() {
		Whitelab.document.loadDocument($("#document-display").data("tab"), $("#document-display").data("xmlid"), $("#document-display").data("query-id"));
	},
	
	loadDocument : function(tab, xmlid, qid, offset, number) {
		Whitelab.debug('QID: '+qid);
		if (tab === 'content' && offset == null)
			offset = 0;
		if (tab === 'content' && number == null)
			number = 50;
		if (tab === 'content') {
			if (qid != null && qid !== '') {
				Whitelab.debug('A: /document/'+xmlid+'/query/'+qid+'/'+tab+'.js?offset='+offset+'&number='+number);
				$.getScript('/document/'+xmlid+'/query/'+qid+'/'+tab+'.js?offset='+offset+'&number='+number);
			} else {
				Whitelab.debug('B: /document/'+xmlid+'/'+tab+'.js?offset='+offset+'&number='+number);
				$.getScript('/document/'+xmlid+'/'+tab+'.js?offset='+offset+'&number='+number);
			}
		} else {
			if (qid != null && qid !== '') {
				Whitelab.debug('C: /document/'+xmlid+'/query/'+qid+'/'+tab+'.js');
				$.getScript('/document/'+xmlid+'/query/'+qid+'/'+tab+'.js');
			} else {
				Whitelab.debug('D: /document/'+xmlid+'/'+tab+'.js');
				$.getScript('/document/'+xmlid+'/'+tab+'.js');
			}
		}
	}
	
};

$(document).on('click', 'a.document-tab', function(e) {
	e.preventDefault();
	if (!$(this).parent().hasClass("active")) {
		$(this).parent().parent().find("li.active").first().removeClass("active");
		$(this).parent().addClass("active");
		$("#document-display div.tab-content").html('<span class="loading"></span>');
		Whitelab.document.loadDocument($(this).data("tab"), $("#document-display").data("xmlid"), $("#document-display").data("query-id"));
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
