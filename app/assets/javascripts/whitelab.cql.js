Whitelab.cql = {
		
	simpleQueryStringToCQL : function(str, caseSensitive) {
		Whitelab.debug("simpleQueryStringToCQL");
		var query = "";
		if (str) {
            var terms = str.split(" ");
            var c = "";
            if (caseSensitive)
                c = "(?c)";
            for (var i = 0; i < terms.length; i++) {
                if (terms[i].length > 0) {
                    var sub = terms[i].substring(0,2);
                    if (sub === '[]' || sub === '[word=\".*\"]') {
                        if (terms[i].indexOf('{,') > -1) {
                            terms[i] = terms[i].replace('{,','{1,');
                        }
                        query = query + terms[i];
                    } else {
                        query = query + "[word=\""+c+terms[i]+"\"]";
                    }
                }
            }
		}
		return query;
	},

	getColumns : function(query) {
	    Whitelab.debug("Whitelab.cql.getColumns");
	    var n = query.indexOf("[");
        var m = -1;
        var columns = [];
        var quants = [];
        var qua1 = '';
        if (n > 1) {
            qua1 = query.substring(0,n);
            if (qua1.indexOf('<s>') == -1) {
                qua1 = '';
            }
        }
        while (n > -1) {
            m = query.indexOf("]",n);
			var c = query.substring(n,m+1);
			var count = (c.match(/"/g) || []).length;
			while (count % 2 == 1) {
				m = query.indexOf("]",m+1);
				c = query.substring(n,m+1);
				count = (c.match(/"/g) || []).length;
			}
			columns.push(c);
            n = query.indexOf("[",m+1);
            if (n == -1) {
                if (query.length > m+1) {
                    quants.push(query.substring(m+1));
                } else {
                    quants.push('');
                }
            } else {
                if (n-m > 1) {
                    quants.push(query.substring(m+1,n));
                } else {
                    quants.push('');
                }
            }
        }
        return {
            columns: columns,
            quants: quants,
            qua1: qua1
        };
	},

	getSubQueries : function(query) {
	    Whitelab.debug("Whitelab.cql.getSubQueries");
	    var arr = new Array();
	    var splits = query.split(/\][\*\{\}0-9\,\+]*\)*\|\(*\[/);
	    for (var i = 0; i < splits.length; i++) {
	        var str = splits[i];
	        if (str.indexOf("[") != 0)
	            str = "["+str;
	        if (str.substr(str.length - 1,1) !== "]")
	            str = str+"]";
	        query = query.substr(str.length + 1, query.length - str.length);
	        var j = query.indexOf("[");
	        if (j > 0) {
	            str = str + query.substr(0,j);
	            query = query.substr(j, query.length - j);
	        }
	        arr.push(str);
	    }
	    return arr;
	},

	combineColumns : function(c1, c2) {
	    Whitelab.debug("Whitelab.cql.combineColumns");
	    var c1_opts = c1.match(/((word|lemma|pos|phonetic)|(\".+\"))/g);
	    c1_opts[1] = c1_opts[1].substr(1,c1_opts[1].length-2);
	    var c2_opts = c2.match(/((word|lemma|pos|phonetic)|(\".+\"))/g);
	    c2_opts[1] = c2_opts[1].substr(1,c2_opts[1].length-2);
//	    if (c1_opts[0] === c2_opts[0]) {
//	        if (c1_opts[1].indexOf(c2_opts[1]) > -1)
//	            return c1;
//	        else
//	            return "["+c1_opts[0]+"=\""+c1_opts[1]+"|"+c2_opts[0]+"=\""+c2_opts[1]+"\"]";
//	    } else
	    if (c1 !== c2 && c1_opts[1].indexOf(c2_opts[1]) == -1)
	        return "["+c1_opts[0]+"=\""+c1_opts[1]+"\"|"+c2_opts[0]+"=\""+c2_opts[1]+"\"]";
	    else
	        return c1;
	},
	
	cqlToAdvancedInterface : function(query) {
		Whitelab.debug("cqlToAdvancedInterface("+query+")");

        if (query.length > 0) {
            var subqueries = Whitelab.cql.getSubQueries(query);
            for (var i = 0; i < subqueries.length; i++) {
                subqueries[i] = Whitelab.cql.getColumns(subqueries[i]);
            }
            Whitelab.debug(subqueries);

            if (subqueries.length > 1) {
                for (var i = 1; i < subqueries.length; i++) {
                    for (var j = 0; j < subqueries[i].columns.length; j++) {
                        subqueries[0].columns[j] = Whitelab.cql.combineColumns(subqueries[0].columns[j],subqueries[i].columns[j]);
                        Whitelab.debug(subqueries[0].columns[j]);
                        if (subqueries[i].quants[j].length > 0)
                            subqueries[0].quants[j] = subqueries[i].quants[j];
                    }
                }
            }
            var columns = subqueries[0].columns;
            var quants = subqueries[0].quants;
            var qua1 = subqueries[0].qua1;

            var c = -1;
            Whitelab.debug("columns: "+columns.length);
            Whitelab.debug(columns);
            while (columns.length > 0) {
                var column = columns.shift();
                Whitelab.debug("column:");
                Whitelab.debug(column);
                var quant = quants.shift();
                var repeat_from = 1;
                var repeat_to = 1;
                var startsen = false;
                var endsen = false;
                var batch = false;
                var sensitive = false;
                var token_type = 'word';
                var operator = 'is';
                var input = null;

                c++;
                var b = -1;

                if (qua1.length > 0) {
                    startsen = true;
                    qua1 = '';
                }

                if (quant && quant.indexOf('</s>') > -1) {
                    endsen = true;
                } else if (quant && quant.indexOf('<s>') > -1) {
                    qua1 = quant;
                } else if (quant && quant.indexOf('{') > -1) {
                    $("#column"+c).find("div.repeat").addClass("active");
                    if (quant.indexOf('{,') > -1) {
                        repeat_from = 0;
                    } else {
                        var nrs = quant.match(/\d+/);
                        repeat_from = nrs[0];
                        quant = quant.replace(nrs[0],'');
                    }
                    var nrs = quant.match(/\d+/);
                    if (nrs != null && nrs.length > 0) {
                        repeat_to = nrs[0];
                    } else
                        repeat_to = '';
                } else if (quant && quant.indexOf('+') > -1) {
                    repeat_from = 1;
                    repeat_to = '';
                } else if (quant && quant.indexOf('*') > -1) {
                    repeat_from = 0;
                    repeat_to = '';
                } else if (quant && quant.indexOf('within') > -1) {
                    if (quant.indexOf('s') > -1) {
                        $("#search-within").val('sentence');
                    } else if (quant.indexOf('p') > -1 || quant.indexOf('event') > -1) {
                        $("#search-within").val('paragraph');
                    }
                }

                var ands = column.split('&');
                Whitelab.debug("ands: "+ands.length);
                while (ands.length > 0) {
                    Whitelab.debug("and: "+ands[0]);
                    b++;
                    var f = -1;
                    var and = ands.shift();

                    var ors = and.split('|');
                    while (ors.length > 0) {
                        f++;
                        var field = document.getElementById("column"+c+"-box"+b+"-field"+f);
                        var or = ors.shift();
                        if (or === '[]' || or === '[word=\".*\"]') {
                            Whitelab.search.advanced.addFieldToBoxInColumn(b, c, "word", "is", ".*", batch, sensitive, startsen, endsen, repeat_from, repeat_to);
                        } else {
                            if (or.indexOf('lemma') > -1) {
                                token_type = 'lemma';
                            } else if (or.indexOf('pos') > -1) {
                                token_type = 'pos';
                            } else if (or.indexOf('phonetic') > -1) {
                                token_type = 'phonetic';
                            }

                            var not = 0;
                            if (or.indexOf('!=') > -1) {
                                not = 1;
                            }

                            var term = or.substring(or.indexOf('"')+1);
                            var q2 = term.indexOf('"');
                            term = term.substring(0,q2);
                            if (term.indexOf('(?i)') > -1) {
                                term = term.substring(4);
                            } else if (term.indexOf('(?c)') > -1) {
                                term = term.substring(5);
                                if (token_type === 'word' || token_type === 'lemma' || token_type === 'phonetic') {
                                    sensitive = true;
                                }
                            }
                            input = term;

                            var dd = 1;
                            if (not == 1) {
                                operator = 'not';
                            } else {
                                var regex = /\.(\*|\+)/gi, result, indices = [];
                                while ( (result = regex.exec(term)) ) {
                                    indices.push(result.index);
                                }
                                if (indices.length == 2 && indices[0] == 0 && indices[1] == term.length - 2) {
                                    dd = 0;
                                    operator = 'contains';
                                } else if (indices.length > 2 || (indices.length == 2 && (indices[0] != 0 || indices[1] != term.length - 2))) {
                                    dd = 0;
                                    operator = 'regex';
                                } else if (indices.length == 1) {
                                    if (indices[0] == 0) {
                                        dd = 0;
                                        operator = 'ends';
                                    } else if (indices[0] == term.length - 2) {
                                        if (token_type === 'pos' && term.match(/^[A-Z]+\.\*/)) {
                                            dd = 1;
                                        } else {
                                            dd = 0;
                                            operator = 'starts';
                                        }
                                    } else {
                                        dd = 0;
                                        operator = 'regex';
                                    }
                                }
                            }
                            if (input.length > 0)
                                Whitelab.search.advanced.addFieldToBoxInColumn(b, c, token_type, operator, input, batch, sensitive, startsen, endsen, repeat_from, repeat_to);
                        }

                        if (ors.length > 0) {
                            $("#advanced-canvas .advanced-column a.add-or").last().click();
                        }
                    }

                    if (ands.length > 0) {
                        $("#advanced-canvas .advanced-column a.add-and").last().click();
                    }

                    Whitelab.sleep(100);
                }
            }
        } else if ($(".advanced-column").length == 0)
            Whitelab.search.advanced.addFieldToBoxInColumn(0, 0);
	},
	
	cqlToExtendedInterface : function(query) {
		var n = query.indexOf("[");
		var m = -1;
		var columns = [];
		var quants = [];
		var batch = false;
		var split = false;
		var wordsensitive = false;
		var lemmasensitive = false;
		var phoneticsensitive = false;
		if (query.indexOf("|") > -1) {
			batch = true;
		}
		while (n > -1) {
			m = query.indexOf("]",n);
			var c = query.substring(n,m+1);
			var count = (c.match(/"/g) || []).length;
			while (count % 2 == 1) {
				m = query.indexOf("]",m+1);
				c = query.substring(n,m+1);
				count = (c.match(/"/g) || []).length;
			}
			columns.push(c);
			n = query.indexOf("[",m+1);
			if (n-m > 1) {
				quants.push(query.substring(m+1,n));
			} else {
				quants.push('');
			}
		}
		
		var cql = new Cql(split,batch);
		for (var i = 0; i < columns.length; i++) {
			var x = cql.addEmptyColumn();
			var column = columns[i];
			var quant = quants[i];
			
			if (column.length > 0) {
				var ands = column.split('&');
				while (ands.length > 0) {
					var and = ands.shift();
					var ors = and.split('|');
					if (and.indexOf(' | ') > -1) {
						ors = and.split(' | ');
					}
					while (ors.length > 0) {
						var or = ors.shift();
						var type = 'word';
						if (or.indexOf('lemma') > -1) {
							type = 'lemma';
						} else if (or.indexOf('pos') > -1) {
							type = 'pos';
						} else if (or.indexOf('phonetic') > -1) {
							type = 'phonetic';
						}
						
						var field = cql.columns[x].getFieldByType(type);
						if (field == null) {
							field = cql.addEmptyFieldToColumn(x);
							field.type = type;
						}
						
						var term = or.substring(or.indexOf('"')+1);
						var q2 = term.indexOf('"');
						term = term.substring(0,q2);
						var sensitive = false;
						if (term.indexOf('(?i)') > -1) {
							term = term.substring(4);
						} else if (term.indexOf('(?c)') > -1) {
							term = term.substring(4);
							sensitive = true;
							if (type === "word")
								wordsensitive = true;
							else if (type === "lemma")
								lemmasensitive = true;
							else if (type === "phonetic")
								phoneticsensitive = true;
						}
						if (term.length == 0) {
							term = '[]';
						}

						var sub = new CqlField(type,term,sensitive,"is",batch,quant);
						field.addSubField(sub);
						Whitelab.debug("("+type+") "+x+" subfield: "+term);
					}
				}
			}
		}
		
		if (cql.batch) {
			Whitelab.debug("cql batch");
			var types = ["word","lemma","pos", "phonetic"];
			for (var t = 0; t < types.length; t++) {
				var type = types[t];
				
				var rows = 0;
				for (var i = 0; i < cql.columns.length; i++) {
					var column = cql.columns[i];
					var field = column.getFieldByType(type);
					if (field != null) {
						var r = field.subfields.length;
						Whitelab.debug("("+type+") field "+i+" has "+r+" rows");
						if (r > rows)
							rows = r;
					}
				}
				if (rows > 0) {
					var vals = [];
					for (var i = 0; i < cql.columns.length; i++) {
						var column = cql.columns[i];
						var field = column.getFieldByType(type);
						var r = field.subfields.length;
						for (var j = 0; j < rows; j++) {
							if (j >= r) {
								// add last non-empty field to row
								if (vals.length == j) {
									vals[j] = [];
								}
								vals[j][i] = field.subfields[r-1].value;
							} else {
								// add value to row
								if (vals.length == j) {
									vals[j] = [];
								}
								Whitelab.debug("("+type+") adding: "+field.subfields[j].value);
								vals[j][i] = field.subfields[j].value;
							}
						}
					}

					$("#extended-"+type+" div.batchrow").addClass("active");
					$("#extended-"+type+" div.inputrow").removeClass("active");
					$("#extended-"+type+" textarea.batchlist").val("");
					
					for (var i = 0; i < vals.length; i++) {
						var val = $("#extended_"+type+" textarea.batchlist").val();
						if (val.length > 0) {
							val = val+"\n"+vals[i].join(" ");
						} else {
							val = vals[i].join(" ");
						}
						Whitelab.debug("VALUE: "+val);
						$("#extended-"+type+" textarea.batchlist").val(val);
					}
				}
			}
			
		} else {
			Whitelab.debug("cql non-batch");
			var types = ["word","lemma","pos", "phonetic"];
			for (var t = 0; t < types.length; t++) {
				var type = types[t];
				
				if (type === "word") {
					Whitelab.debug("wordsensitive: "+wordsensitive);
					$("#extended-word input[type='checkbox']").prop("checked",wordsensitive);
				}
				if (type === "lemma") {
					Whitelab.debug("lemmasensitive: "+lemmasensitive);
					$("#extended-lemma input[type='checkbox']").prop("checked",lemmasensitive);
				}
				if (type === "phonetic") {
					Whitelab.debug("phoneticsensitive: "+phoneticsensitive);
					$("#extended-phonetic input[type='checkbox']").prop("checked",phoneticsensitive);
				}
				
				var vals = [];
				for (var i = 0; i < cql.columns.length; i++) {
					var column = cql.columns[i];
					var field = column.getFieldByType(type);
					if (field != null) {
						Whitelab.debug("field is of type "+type);
						if (type === "pos" && field.subfields.length > 1) {
							for (var j = 0; j < field.subfields.length; j++) {
								if (field.subfields[j].value.length > 0)
									vals.push(field.subfields[j].value);
							}
						} else if (field.subfields[0].value.length == 0)
							vals.push("[]");
						else
							vals.push(field.subfields[0].value);
					} else {
						Whitelab.debug("field "+type+" is null");
					}
				}
				if (vals.length > 0) {
					if (type === "pos") {
						if ($("#extended #pos-text option[value='"+vals[0]+"']").length > 0) {
							$("#extended #"+type+"-text").val(vals[0]);
							$("#extended-refine-pos").removeClass("hidden");
							var pos = vals.shift();
							if (vals.length > 0) {
								$("#refine-pos").removeClass("hidden");
								for (var i = 0; i < vals.length; i++) {
									vals[i] = vals[i].replace(/[^0-9a-z\-]/g, "");
								}
								$.getScript("/search/pos/features.js?pos="+pos+"&values="+vals.join(","));
							}
						} else {
							$("#extended-pos .searchinput").html('<input type="text" id="pos-text" name="pos" value="'+vals.join(" ")+'" />');
						}
					} else {
						var val = vals.join(" ");
						$("#extended #"+type+"-text").val(val);
					}
				}
			}
		}
	},
	
	cqlToNgramsInterface : function(cql,size,group) {
		Whitelab.debug("cqlToNgramsInterface("+cql+","+size+","+group+")");
		cql = cql.substr(1);
		var parts = cql.split('[');
		var k = 0;
		var set = [];
		if (parts.length == size) {
			set = parts;
		} else {
			for (var i = 0; i < parts.length; i++) {
				var part = parts[i];
				var quant = part.substring(part.indexOf(']')+1);
				if (quant.length > 0) {
					var q = parseInt(quant.substring(1,2));
					part = part.substring(0,part.indexOf(']')+1);
					for (var k = 0; k < q; k++) {
						set.push(part);
					}
				} else {
					set.push(part);
				}
			}
		}
		for (var i = 0; i < set.length; i++) {
			var part = set[i];
			var val = part.substring(0,part.indexOf(']'));
			var type = "word";
			var input = "";
			if (val.length > 0) {
				if (val.indexOf("=") > -1) {
					var v = val.split('=');
					type = v[0];
					input = v[1].replace(/"/g,'');
				} else {
					type = "word";
					input = val;
				}
			}
			var j = i + 1;
			$("#type-"+j).val(type);
			if (type === 'pos' && input.match(/^[A-Z]+$/)) {
				Whitelab.explore.ngrams.setTokenInput($("#type-"+j),input);
			} else if (input !== '' && input !== '.*')
				$("#field-"+j+" .field-input").val(input);
		}
		if (size < 5) {
			for (var i = size+1; i <= 5; i++) {
				$('#type-'+i).prop('disabled', 'disabled');
				$("#field-"+i+" .field-input").prop('disabled', 'disabled');
			}
		}
		group = group.replace(/hit:/,'');
		$("#ngram-groupSelect").val(group);
	},
	
	advancedQueryStringToCQL : function() {
		var nrBatchFields = 0;
		$("#advanced").find(".batchrow").each(function() {
			if ($(this).hasClass('hide') == false) {
				nrBatchFields++;
			}
		});
		
		var split = $("#advanced .splitcheck").is(":checked");
		var batch = nrBatchFields > 0 ? true : false;
		var query = new Cql(split,batch);
		
		$(document).find(".advanced-column").each(function() {
			var i = query.addEmptyColumn();
			
			$(this).find(".advanced-box").each(function(j,and) {
				var f = query.addEmptyFieldToColumn(i);
				if ($(and).find(".advanced-field").length > 1) {
					Whitelab.debug("Multiple fields");
					$.each($(and).find(".advanced-field"), function(j,or) {
						if (!$(or).find(".batchrow").first().hasClass("active")) {
							Whitelab.debug("no batch");
							var sub = new CqlField(null,null,false,null,false,null);
							sub.type = $(or).find(".token-type").first().val();
							Whitelab.debug("sub type: "+sub.type);
							sub.operator = $(or).find(".token-operator").first().val();
							Whitelab.debug("sub operator: "+sub.operator);
							sub.sensitive = $(or).find("div.token-case input").prop('checked');
							Whitelab.debug("sub sensitive: "+sub.sensitive);
							var boxval = Whitelab.search.advanced.getBoxValue(or,sub.type,sub.operator);
							Whitelab.debug("sub boxval: "+boxval);
							sub.value = Whitelab.cql.removeQuantifier(boxval);
							Whitelab.debug("sub value: "+sub.value);
							sub.quantifier = Whitelab.cql.removeValue(boxval);
							Whitelab.debug("sub quantifier: "+sub.quantifier);
							f.addSubField(sub);
						} else {
							Whitelab.debug("batch");
							f.batch = true;
							var vals = Whitelab.search.advanced.getBoxValues(or);
							for (var v = 0; v < vals.length; v++) {
								var sub = new CqlField(null,null,false,null,false,null);
								sub.type = $(or).find(".token-type").first().val();
								sub.operator = $(or).find(".token-operator").first().val();
								sub.sensitive = $(or).find("div.token-case input").prop('checked');
								sub.value = Whitelab.cql.removeQuantifier(vals[v]);
								sub.quantifier = Whitelab.cql.removeValue(vals[v]);
								f.addSubField(sub);
							}
						}
					});
				} else if (!$(and).find(".batchrow").first().hasClass("active")) {
					Whitelab.debug("One field, no batch");
					// 1 field filled, no batch
					f.type = $(and).find(".token-type").first().val();
					f.operator = $(and).find(".token-operator").first().val();
					f.sensitive = $(and).find("div.token-case input").prop('checked');
					var boxval = Whitelab.search.advanced.getBoxValue(and,f.type,f.operator);
					f.value = Whitelab.cql.removeQuantifier(boxval);
					f.quantifier = Whitelab.cql.removeValue(boxval);
				} else {
					Whitelab.debug("One field, batch");
					// 1 field filled, batch
					var vals = Whitelab.search.advanced.getBoxValues(and);
					f.batch = true;
					f.type = $(and).find(".token-type").first().val();
					for (var v = 0; v < vals.length; v++) {
						var sub = new CqlField(null,null,false,null,false,null);
						sub.type = $(and).find(".token-type").first().val();
						sub.operator = $(and).find(".token-operator").first().val();
						sub.sensitive = $(and).find("div.token-case input").prop('checked');
						sub.value = Whitelab.cql.removeQuantifier(vals[v]);
						sub.quantifier = Whitelab.cql.removeValue(vals[v]);
						f.addSubField(sub);
					}
				}
			});
			
			if ($(this).find("div.repeat").hasClass("active")) {
				var from = $(this).find("input.from").val();
				var to = $(this).find("input.to").val();
				query.columns[i].quantifier = "{"+from+","+to+"}";
			}
			
			if ($(this).find("span.startsen").hasClass("active")) {
				query.columns[i].before = "<s>";
			}
			
			if ($(this).find("span.endsen").hasClass("active")) {
				query.columns[i].after = "</s>";
			}
			
		});
		return query.getQuery();
	},

	expertQueryStringToCQL : function() {
		Whitelab.debug("expertQueryStringToCQL");
	    return $("#expert-input").val();
	},
	
	extendedQueryStringToCQL : function() {
		Whitelab.debug("extendedQueryStringToCQL");
		var batch = false;
		if (!$("#extended-word .batchrow").is(':hidden') ||
			!$("#extended-lemma .batchrow").is(':hidden') ||
			!$("#extended-pos .batchrow").is(':hidden') ||
			!$("#extended-phonetic .batchrow").is(':hidden')) {
			batch = true;
		}
		var split = $("#extended .splitcheck").is(":checked");
		var query = new Cql(split,batch);
		
		var types = ["word","lemma","pos","phonetic"];
		$.each(types, function(t,type) {
			if ($("#extended-"+type+" .inputrow").hasClass('active')) {
				var textInput = document.getElementById(type+"-text");
				Whitelab.debug(textInput);
				if ($(textInput).val().length > 0) {
					var vals = $(textInput).val().split(" ");
					for (var v = 0; v < vals.length; v++) {
						if (query.columns.length <= v) {
							query.addEmptyColumn();
						}
						var f = query.addEmptyFieldToColumn(v);
						f.type = type;
						f.operator = "is";
						if (["word","lemma","phonetic"].indexOf(type) > -1) {
							f.sensitive = $("#extended-"+type+" input[type='checkbox'].wordcase").is(":checked");
							Whitelab.debug("extendedQueryStringToCQL f.sensitive = "+f.sensitive);
						}
						f.value = Whitelab.cql.removeQuantifier(vals[v]);
						f.quantifier = Whitelab.cql.removeValue(vals[v]);
						if (type === "pos") {
							$.each(document.getElementsByClassName("pos-feat-select"), function(pf,feat) {
								var feat_val = $(feat).val();
								if (feat_val !== "") {
									var pff = query.addEmptyFieldToColumn(v);
									pff.type = $(feat).attr("id");
									pff.operator = "is";
									pff.value = feat_val;
								}
							});
						}
					}
				}
			} else if (!$("#extended-"+type+" .batchrow").is(':hidden')) {
				var lines = $("#extended-"+type+" .batchlist").val().split("\n");
				$.each(lines, function(l,line) {
					if (line.length > 0) {
						var vals = line.split(" ");
						for (var v = 0; v < vals.length; v++) {
							if (query.columns.length <= v) {
								query.addEmptyColumn();
							}
							var column = query.columns[v];
							var f = column.getFieldByType(type);
							if (f == null) {
								f = query.addEmptyFieldToColumn(v);
								f.type = type;
							}
							var sub = new CqlField(type,null,false,"is",true,null);
							if (type === "word" || type === "lemma" || type === "phonetic") {
								sub.sensitive = $("#extended-"+type+" input.wordcase").prop('checked');
							}
							sub.value = Whitelab.cql.removeQuantifier(vals[v]);
							sub.quantifier = Whitelab.cql.removeValue(vals[v]);
							f.addSubField(sub);
						}
					}
				});
			}
		});
		
		return query.getQuery();
	},
	
	removeQuantifier : function (boxval) {
		var regex = /(\{\d*,*\d*\}$)/;
		var match = regex.exec(boxval);
		if (match != null) {
			var res = boxval.replace(match[0],"");
			return res;
		} else {
			return boxval;
		}
	},
	
	removeValue : function (boxval) {
		var regex = /(\{\d*,*\d*\}$)/;
		var match = regex.exec(boxval);
		if (match != null) {
			return match[0];
		} else {
			return null;
		}
	},
	
	cqlToSimpleQueryString : function(cql) {
		Whitelab.debug("cqlToSimpleQueryString("+cql+")");
		var terms = cql.split("][");
		var words = [];
		for (var i = 0; i < terms.length; i++) {
			var term = terms[i].replace(/[\[\]]/g,'');
			var myRegexp = /("|&quot;)(.+)("|&quot;)/g;
			var match = myRegexp.exec(term);
			words.push(match[2]);
		}
		return words.join(" ");
	}
	
};