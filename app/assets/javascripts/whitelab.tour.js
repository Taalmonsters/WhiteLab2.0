Whitelab.tour = {
	active : false,
	steps : null,
	nextUrl : null,
	intro: null,
	
	init : function() {
		Whitelab.tour.intro = introJs().oncomplete(function() {
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
	}
};