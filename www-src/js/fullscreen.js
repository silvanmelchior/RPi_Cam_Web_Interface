(function($, document){
	$(document).ready(function(){
		$('#mjpeg_dest').click(function(){
			var background = $('#background');
			if (background.length === 0) {
				background = $('<div>').attr('id', 'background').appendTo('body');
			}
			$(this).toggleClass('fullscreen');
			if ($(this).hasClass('fullscreen')) {
				background.show();
			} else {
				background.hide();
			}
		});
	});
})(jQuery, document);