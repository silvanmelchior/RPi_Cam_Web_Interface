/*global thumbnails,previewWidth,linksBase,mediaBase*/
function load_preview(thumbnail) {
	var prevButton = document.getElementsByName('prev')[0];
	var nextButton = document.getElementsByName('next')[0];
	var mediaDiv = document.getElementById('media');
	var imageIndex = thumbnails.indexOf(thumbnail);
	var prev, next;
	if (imageIndex > 0) {
		prev = thumbnails[imageIndex-1];
	}
	if (imageIndex >= 0 && imageIndex < thumbnails.length-1) {
		next = thumbnails[imageIndex+1];
	}

	if (prev) {
		prevButton.disabled = false;
		prevButton.onclick = function() {
			load_preview(prev);
		}
	} else {
		prevButton.disabled = true;
	}

	if (next) {
		nextButton.disabled = false;
		nextButton.onclick = function() {
			load_preview(next);
		}
	} else {
		nextButton.disabled = true;
	}

	var mediaURL = mediaBase + imageFromThumbnail(thumbnail);
	if (mediaURL) {
		var media_content;
		if (fileExtension(mediaURL) == 'jpg') {
			var linkURL = linksBase + thumbnail;
			media_content = '<a href="' + linkURL + '" target="_blank"><img src="' + mediaURL + '" style="width: ' + previewWidth + 'px;"></a>';
		} else {
			media_content = '<video style="width:' + previewWidth + '"px;" controls><source src="' + mediaURL + '" type="video/mp4">Your browser does not support the video tag.</video>';
		}

		mediaDiv.innerHTML = media_content;
	}
}

function imageFromThumbnail(thumbnailName) {
	var suffix = '.v0000.th.jpg';
	return thumbnailName.substr(0, thumbnailName.length - suffix.length);
}

function fileExtension(fileName) {
	return fileName.split('.').pop();
}