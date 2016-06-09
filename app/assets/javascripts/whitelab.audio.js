Whitelab.audio = {
	audioLink : null,
	element : null,
	elementInitialized : false,
	
	playSegment : function(audioLink,url,begin_time,end_time) {
		Whitelab.audio.audioLink = audioLink;
		$(Whitelab.audio.audioLink).find('span').first().removeClass("glyphicon-play").addClass("glyphicon-pause");
		$(Whitelab.audio.audioLink).addClass('playing');
		Whitelab.audio.element = new Audio(url);
		Whitelab.audio.elementInitialized = false;
		Whitelab.audio.element.addEventListener('timeupdate', function() {
	    	if (this.currentTime >= end_time) {
	    		this.pause();
	    		this.currentTime = begin_time;
	    		Whitelab.audio.stopSegment();
	    	}
		}, false);
		Whitelab.audio.element.load();
		Whitelab.audio.element.addEventListener('canplaythrough', function() {
			if (!Whitelab.audio.elementInitialized) {
				if (this.currentTime < begin_time) {
					this.currentTime = begin_time;
					Whitelab.audio.elementInitialized = true;
					Whitelab.audio.element.play();
				}
			}
		}, false);
	},
	
	stopSegment : function() {
		if (Whitelab.audio.element != null) {
			Whitelab.audio.element.pause();
			Whitelab.audio.element = null;
			Whitelab.audio.elementInitialized = false;
			$(Whitelab.audio.audioLink).find('span').first().removeClass("glyphicon-pause").addClass("glyphicon-play");
			$(Whitelab.audio.audioLink).removeClass('playing');
			Whitelab.audio.audioLink = null;
		}
	},
	
	timeToSeconds : function(t) {
		Whitelab.debug("Whitelab.audio.timeToSeconds("+t+")");
		var i = t === '00:00:00.000' ? 1 : 0;
		var parts = t.split(":");
		return parseFloat(parts[2]) + (60 * parseInt(parts[1])) + (3600 * parseInt(parts[0]) + i);
	}
};

$(document).on('click', 'a.playsound', function(e) {
	e.preventDefault();
	var url = $(this).data('audio-url');
	var begin_time = Whitelab.audio.timeToSeconds($(this).data('begin-time'));
	var end_time = Whitelab.audio.timeToSeconds($(this).data('end-time'));
	
	if (!$(this).hasClass('playing')) {
		Whitelab.audio.stopSegment();
		Whitelab.audio.playSegment(this,url,begin_time,end_time);
	} else
		Whitelab.audio.stopSegment();
});
