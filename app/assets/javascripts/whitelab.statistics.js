Whitelab.statistics = {
	
	displayDocumentSizeBubbleChart : function(json) {
		var locale = $("#main-div").data("locale");
		var bubbleColors = d3.scale.linear()
		.domain([0,json.max_doc_count])
		.range(["#53c4c3", "#9b0122"]);
		
		$('#bubble-chart').highcharts({

	        chart: {
	            type: 'bubble',
	            plotBorderWidth: 1
	        },

	        legend: {
	            enabled: false
	        },

	        title: {
	            text: "Total size versus average document size"
	        },

	        xAxis: {
	        	min: 0,
	            startOnTick: true,
	            endOnTick: false,
	            gridLineWidth: 1,
	            title: {
	                text: 'Total size (tokens)'
	            },
	            labels: {
	                format: '{value:,.0f}'
	            }
	        },

	        yAxis: {
	        	min: 0,
	            startOnTick: true,
	            endOnTick: false,
	            title: {
	                text: 'Avg. document size (tokens)'
	            },
	            labels: {
	                format: '{value:,.0f}'
	            },
	            maxPadding: 0.2
	        },

	        tooltip: {
	        	borderColor: '#999',
	            useHTML: true,
	            headerFormat: '<table class="table">',
	            pointFormat: '<tr><th colspan="2"><h3>{point.name}</h3></th></tr>' +
	            	'<tr><th>Document count:</th><td>{point.z:,.0f}</td><td>({point.z2} %)</td></tr>' +
	                '<tr><th>Total size:</th><td>{point.x:,.0f} tokens</td><td>({point.x2} %)</td></tr>' +
	                '<tr><th>Average document size:</th><td>{point.y:,.0f} tokens</td></tr>',
	            footerFormat: '</table>',
	            followPointer: false
	        },

	        plotOptions: {
	            series: {
	                dataLabels: {
	                    enabled: true,
	                    format: '{point.name}'
	                }
	            }
	        },

	        series: (function() {
	        	var arr = [];
	        	for (var i = 0; i < json.data.length; i++) {
	    			var row = json.data[i];
	    			Whitelab.debug(row.z+" = "+bubbleColors(row.z));
	    			arr.push({ data: [row], marker: { fillColor: bubbleColors(row.z), lineColor: bubbleColors(row.z) } });
	    		}
	        	return arr;
	        }())

	    });
		
		
	},
	
	displayPosDistribution : function(json) {
		Highcharts.getOptions().plotOptions.pie.colors = (function () {
	        var colors = [],
	            base = '#317777',
	            i;

	        for (i = 0; i < 12; i += 1) {
	            // Start out with a darkened base color (negative brighten), and end
	            // up with a much brighter color
	            colors.push(Highcharts.Color(base).brighten((i - 2) / 13).get());
	        }
	        return colors;
	    }());
		
		$('#pos-distribution-display').html("");
		$('#pos-distribution-display').highcharts({
	        chart: {
	            plotBackgroundColor: null,
	            plotBorderWidth: null,
	            plotShadow: false,
	            type: 'pie'
	        },
	        
	        title: {
                text: json['title']
            },

            tooltip: {
                pointFormat: '<b>{point.y:,.0f} ({point.percentage:.1f}%)</b>'
            },

            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: true,
                        format: '<b>{point.name}</b>: {point.percentage:.1f} %',
                        style: {
                            color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                        }
                    }
                }
            },

            series: [{
            	name: '',
            	data: json['data']
            }]
			
		});
	},
	
	loadPosDistribution : function(url) {
	    $.getJSON(url, function (json) {
			Whitelab.statistics.displayPosDistribution(json);
		});
	},
	
	displayVocabularyGrowth : function(json) {
		Whitelab.debug('displayVocabularyGrowth');
		Whitelab.debug(json);
		$('#vocabulary-growth-display').html("");
        $('#vocabulary-growth-display').highcharts({

            title: {
                text: json['title']
            },

            xAxis: {
                tickWidth: 1,
                gridLineWidth: 1,
                labels: {
                    align: 'left',
                    x: 3,
                    y: -3,
	                format: '{value:,.0f}'
	            }
            },

            yAxis: [{ // left y axis
                title: {
                    text: null
                },
                labels: {
                    align: 'left',
                    x: 3,
                    y: 16,
	                format: '{value:,.0f}'
                },
                showFirstLabel: false
            }, { // right y axis
                linkedTo: 0,
                gridLineWidth: 0,
                opposite: true,
                title: {
                    text: null
                },
                labels: {
                    align: 'right',
                    x: -3,
                    y: 16,
	                format: '{value:,.0f}'
                },
                showFirstLabel: false
            }],

            legend: {
                align: 'left',
                verticalAlign: 'top',
                floating: true,
                borderWidth: 0
            },

            tooltip: {
                shared: false,
                crosshairs: false,
	        	borderColor: '#999',
	            useHTML: true,
	            headerFormat: '<table class="table">',
	            pointFormat: '<tr><th colspan="2"><h3>{point.name}</h3></th></tr>' +
	            	'<tr><th>Unique {point.ggroup}:</th><td>{point.y}</td><td>({point.y2} %)</td></tr>' +
	                '<tr><th>Progress:</th><td>{point.x} tokens</td><td>({point.x2} %)</td></tr>',
	            footerFormat: '</table>',
	            followPointer: false
            },

            plotOptions: {
                line: {
	                turboThreshold: json['data'][0]['data'].length    
                },
                
                series: {
                    cursor: 'pointer',
                    marker: {
                        lineWidth: 1
                    }
                }
            },

            series: json['data']
        });
	},
	
	loadVocabularyGrowth : function(url) {
		Whitelab.debug('loadVocabularyGrowth');
		$.getJSON(url, function (json) {
			Whitelab.statistics.displayVocabularyGrowth(json);
	    });
	}
	
};