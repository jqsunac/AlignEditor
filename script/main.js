$(function(){

/**
 * 
 * Update homology string and check the irregular style.
 *
 */
function checkStyle(activeFormId) {
	var idx = activeFormId.split("_");
	var estSeq = $("#estSeq_" + idx[1]).val();
	var genomeSeq = $("#genomeSeq_" + idx[1]).val();
	var seqLength = estSeq.length < genomeSeq.length ? estSeq.length : genomeSeq.length;

	var homologyString = "";
	var missedStyle = false;

	for (var i = 0; i < seqLength; i++) {
		var estChar = estSeq.slice(i, i + 1);
		var genomeChar = genomeSeq.slice(i, i + 1);
		if (estChar != "-" && estChar != "." &&
				genomeChar != "-" && genomeChar != "." &&
				estChar == genomeChar) {
			homologyString += "|";
		} else {
			homologyString += " ";
		}
	}
	if (homologyString.match(/\| +\|/)) {
		missedStyle = true;
	}


	$("#isMatch_" + idx[1]).val(homologyString);
	
	if (missedStyle) {
		console.log("estSeq_" + idx[1]);
		$("#isMatch_" + idx[1]).css("background-color", "#f6ad49");
	} else {
		$("#isMatch_" + idx[1]).css("background-color", "#ffffff");
	}
	if (estSeq.length < genomeSeq.length) {
		$("#estSeq_" + idx[1]).css("background-color", "#c7dc68");
	} else if (genomeSeq.length < estSeq.length) {
		$("#genomeSeq_" + idx[1]).css("background-color", "#c7dc68");
	} else {
		$("#estSeq_" + idx[1]).css("background-color", "#ffffff");
		$("#genomeSeq_" + idx[1]).css("background-color", "#ffffff");
	}

}


function resizeInputForm(activeFormId) {
	var idx = activeFormId.split("_");
	var estSeq = $("#estSeq_" + idx[1]).val();
	var genomeSeq = $("#genomeSeq_" + idx[1]).val();
	var seqLength = estSeq.length < genomeSeq.length ? estSeq.length : genomeSeq.length;
	seqLength = (seqLength + 8) * 12;
console.log(seqLength);
	$("#estSeq_" + idx[1]).css("width", seqLength + "px");
	$("#genomeSeq_" + idx[1]).css("width", seqLength + "px");
	$("#isMatch_" + idx[1]).css("width", seqLength + "px");
}


$("input").mouseover(function(e){
	var formId = $(this).attr("id")
	console.log("log id =" + formId);
	if (formId != null) {
		if (formId.match(/^genomeSeq_/) || (formId.match(/^estSeq_/))) {
			checkStyle(formId);
		}
	}
});


//function checkAllStyle() {
$("#chkAllStyle").click(function(){
	$("input").each(function(i) {
		var formId = $(this).attr("id");
		if (formId != null) {
			if (formId.match(/^genomeSeq_/)) {
				checkStyle(formId);
				resizeInputForm(formId);
			}
		}
	});
	return false;
});

/**
 * 
 * Animation for scroll page.
 * 
 */
$("a[href^=#]").click(function(){
	if ($(this).attr("id") == "chkAllStyle") {
		return false;
	}
	var hash = $(this.hash);
	var offset = $(hash).offset().top;
	$("html,body").animate({
		scrollTop: offset
	}, 1000);
	return false;
});



/**
 * Finished jquery.
 */
});


