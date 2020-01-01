Whitelab.admin = {
	meta_dialog : null,
	pos_dialog : null,
	
	init : function() {
		
		if ($('#metadata div.metadata-list').length > 0) {
			$.getScript(Whitelab.getListPage('#metadata',BASE_PATH + '/metadata/index.js',null,null,null,null));
			Whitelab.admin.meta_dialog = $( "#metadatum-dialog" ).dialog({
				closeOnEscape: true,
				draggable: false,
				autoOpen: false,
				width: 'auto',
				width: 600,
				height: 525,
				modal: true,
				resizable: false,
				buttons: {
				},
				close: function() {
					$('#metadatum-dialog div.edit-form').html('<span class="loading"></span>');
					$('#metadatum-dialog div.value-list').html('<span class="loading"></span>');
					$('#metadatum-dialog').dialog('option', 'title', 'Loading...');
					$.getScript(Whitelab.getListPage('#metadata',BASE_PATH + '/metadata/index.js',null,null,null,null));
				}
			});
		}
		
		if ($('#pos-tags div.pos-tags-list').length > 0) {
			$.getScript(Whitelab.getListPage('#pos-tags',BASE_PATH + '/pos/index.js',null,null,null,null));
			Whitelab.admin.pos_dialog = $( "#pos-tag-dialog" ).dialog({
				closeOnEscape: true,
				draggable: false,
				autoOpen: false,
				width: 500,
				minWidth: 500,
				height: 600,
				maxHeight: 600,
				modal: true,
				resizable: false,
				close: function() {
					$('#pos-tag-dialog').dialog('option', 'title', 'Loading...');
					$('#pos-tag-dialog div.feature-list').html('<span class="loading"></span>');
					$('#pos-tag-dialog div.word-type-list').html('<span class="loading"></span>');
				}
			});
		}
		
		if ($('#pos-heads div.pos-heads-list').length > 0) {
			$.getScript(Whitelab.getListPage('#pos-heads',BASE_PATH + '/poshead/index.js',null,null,null,null));
			Whitelab.admin.pos_dialog = $( "#pos-head-dialog" ).dialog({
				closeOnEscape: true,
				draggable: false,
				autoOpen: false,
				width: 1000,
				minWidth: 1000,
				height: 800,
				maxHeight: 800,
				modal: true,
				resizable: false,
				close: function() {
					$('#pos-head-dialog').dialog('option', 'title', 'Loading...');
					$('#pos-head-dialog div.feature-list').html('<span class="loading"></span>');
					$('#pos-head-dialog div.word-type-list').html('<span class="loading"></span>');
				}
			});
		}

		if ($("tr.benchmark-query.waiting").length > 0) {
			Whitelab.admin.performBenchmarkTests();
		}

		if ($(".wysihtml5").length > 0) {
		    $('.wysihtml5').each(function(i, elem) {
                $(elem).wysihtml5();
            });
		}
	},
	
	performBenchmarkTests : function() {
		var queryRow = $("tr.benchmark-query.waiting").first();
		queryRow.removeClass("waiting").addClass("running");
		queryRow.find("td.status").html("Running");
		$.getScript(BASE_PATH + '/admin/benchmark?id='+queryRow.attr('id')+'&cql='+queryRow.find("td.cql").html());
		if ($("tr.benchmark-query.waiting").length > 0) {
			Whitelab.admin.performBenchmarkTests();
		}
	},

	getList : function(url,number,offset,sort,order) {
		params = [];
		if (typeof number !== 'undefined')
			params.push('number='+number);
		if (typeof offset !== 'undefined')
			params.push('offset='+offset);
		if (typeof sort !== 'undefined')
			params.push('sort='+sort);
		if (typeof order !== 'undefined')
			params.push('order='+order);
		$.getScript(url+'?'+params.join('&'));
	},

	getPosHeadList : function(sort,order) {
		url = BASE_PATH + '/poshead/index.js';
		Whitelab.admin.getList(url,null,null,sort,order);
	},

	getPosTagList : function(number,offset,sort,order) {
		url = BASE_PATH + '/pos/index.js';
		Whitelab.admin.getList(url,number,offset,sort,order);
	}
	
};

$(document).on( "click", "#metadata tr.metadatum", function() {
	Whitelab.admin.meta_dialog.dialog( "open" );
	var label = $(this).data("metadatum-label");
	$.getScript(BASE_PATH + '/metadata/'+label+'/edit.js');
});

$(document).on( "click", "#pos-tags tr.pos-tag", function() {
	Whitelab.admin.pos_dialog.dialog( "open" );
	var label = $(this).data("pos-tag-label");
	$.getScript(BASE_PATH + '/pos/'+label+'/show.js');
});

$(document).on( "click", "#pos-heads tr.pos-head", function() {
	Whitelab.admin.pos_dialog.dialog( "open" );
	var label = $(this).data("pos-head-label");
	$.getScript(BASE_PATH + '/poshead/'+label+'/show.js');
});

$(document).on('click', 'button.benchmark-report-button', function(e) {
	var id = $(this).parent().parent().attr("id");
	$("#"+id+"-report").toggleClass("hidden");
});