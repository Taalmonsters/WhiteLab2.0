//This is a manifest file that'll be compiled into application.js, which will include all the files
//listed below.

//Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
//or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.

//It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
//compiled file.

//Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
//about supported directives.

//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require d3.min
//= require whitelab
//= require intro
//= require turbolinks
//= require_tree .

var ready;

ready = function() {
	Whitelab.init();
};

$(document).on('click', 'a.metadata-remove-rule', function(e) {
	e.preventDefault();
	e.stopPropagation();
	if ($('div.rule').length > 1) {
		$(this).parent().parent().remove();
		Whitelab.metadata.updateCoverage();
	}
});
$(document).on('click', 'a.metadata-add-rule', function(e) {
	console.log("CLICK");
	e.preventDefault();
	e.stopPropagation();
	Whitelab.metadata.addMetadataRule();
});

$(document).ready(ready);
$(document).on('page:load', ready);




