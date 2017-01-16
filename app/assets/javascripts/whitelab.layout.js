Whitelab.layout = {
	
	resize : function() {
		Whitelab.layout.adapted_full_width();
//		Whitelab.layout.float_center();
//		Whitelab.layout.pull_down();
	},

	adapted_full_width : function() {
		$('.full-width-minus-siblings').each(function() {
			var w = Whitelab.layout.get_all_siblings_width(this)+8;
			var d = $(this).outerWidth() - $(this).width();
			var ww = $(this).parent().innerWidth()-w-d-25;
		    $(this).css('width', Math.max(0,ww));
		});
	},

	float_center : function() {
		$('.float-center').each(function() {
			var h = Whitelab.layout.get_all_siblings_height(this);
			var m = 0;
			if ($(this).hasClass('pull-top'))
				m = $(this).data('margin-top');
		    $(this).css('margin-top', Math.max(50,($(this).parent().height()-$(this).height()-h)/2)-m);
		});
	},

	pull_down : function() {
		$('.pull-down').each(function() {
			var h = Whitelab.layout.get_all_siblings_height(this);
		    $(this).css('margin-top', Math.max(10,$(this).parent().height()-$(this).height()-h));
		});
	},
	
	get_all_siblings_width : function(el) {
		var w = 0;
		$(el).siblings().each(function() {
			w = w + $(this).outerWidth();
		});
		return w;
	},
	
	get_all_siblings_height : function(el) {
		var h = 0;
		$(el).siblings().each(function() {
			h = h + $(this).height();
		});
		return h;
	}

};
