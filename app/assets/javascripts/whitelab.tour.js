Whitelab.tour = {
	active : false,
	steps : null,
	nextUrl : null,
	intro : null,
	element : null,
	offset : 0,
	
	init : function() {
		Whitelab.tour.intro = introJs().onchange(function(target) {
			var current = this._currentStep;
			var step = this._options.steps[this._currentStep];
			if ("element" in step)
				Whitelab.tour.element = step["element"];
			else
				Whitelab.tour.element = null;
			if ("offset" in step)
				Whitelab.tour.offset = step["offset"];
			else
				Whitelab.tour.offset = 0;
			Whitelab.tour.setScrollTop();
		}).oncomplete(function() {
			if (Whitelab.tour.nextUrl != null)
				window.location = Whitelab.tour.nextUrl;
			else 
				window.location = '/tour/end';
		}).onexit(function() {
			window.location = '/tour/end';
		});
		
		Whitelab.tour.intro.setOptions({
          	steps: Whitelab.tour.steps,
    		showStepNumbers: false
        });

		Whitelab.tour.intro.start();
	},
	
	setScrollTop : function(current) {
		if (Whitelab.tour.element != undefined) {
			var pos = $(Whitelab.tour.element).offset().top - Whitelab.tour.offset - 268;
			$("body").animate({
		        scrollTop: pos
		    }, 200);
		}
	}
};