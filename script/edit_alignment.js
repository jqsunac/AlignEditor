/*Edit Alignment Javascript*/
$(function(){

	//Get selector's id when clicked.
	var fieldId;
	$("input").click(function(){
		var seqId = $(this).attr("id");
		var seqStr;
		var seqLen;
		//Get selected sequence.
		seqStr = $('#' + seqId).getSelection();
		seqLen = seqStr.length;

		//If seqStr =~ /[a-zA-Z]/ , then be insert gaps mode.
		if (seqStr.match(/[a-zA-Z]/)) {
			for(var i = 0; i < seqLen; i++){
				$('#' + seqId).insertBeforeSelection('-');
			}
		}
		//If seqStr =~ /\-*/ , then be delete gaps mode.
		else {
			$('#' + seqId).replaceSelection('');
		}

		
		
	});


});

