/*global thumbnails,previewWidth,linksBase,mediaBase*/
var thumbinailSuffix = '.v0000.th.jpg';

function load_preview(thumbnail) {
	var prevButton = document.getElementsByName('prev')[0];
	var nextButton = document.getElementsByName('next')[0];
	var mediaDiv = document.getElementById('media');
	var title = document.getElementById('media-title');

	title.innerHTML = fileTitle(thumbnail);

	var imageIndex = thumbnails.indexOf(thumbnail);

	// Previous 
	if (imageIndex > 0) {
		var prev = thumbnails[imageIndex-1];
		prevButton.disabled = false;
		prevButton.onclick = function() {
			history.pushState(null, null, linksBase + prev);
			load_preview(prev);
		}
	} else {
		prevButton.disabled = true;
	}

	// Next
	if (imageIndex >= 0 && imageIndex < thumbnails.length-1) {
		var next = thumbnails[imageIndex+1];
		nextButton.disabled = false;
		nextButton.onclick = function() {
			history.pushState(null, null, linksBase + next);
			load_preview(next);
		}
	} else {
		nextButton.disabled = true;
	}

	var mediaURL = mediaBase + imageFromThumbnail(thumbnail);
	if (mediaURL) {
		var media_content;
		if (fileExtension(mediaURL) == 'jpg') {
			media_content = '<a href="' + mediaURL + '" target="_blank"><img src="' + mediaURL + '" style="width: ' + previewWidth + 'px;"></a>';
		} else {
			media_content = '<video style="width:' + previewWidth + '"px;" controls><source src="' + mediaURL + '" type="video/mp4">Your browser does not support the video tag.</video>';
		}

		mediaDiv.innerHTML = media_content;
	}
}

function imageFromThumbnail(thumbnailName) {
	return thumbnailName.substr(0, thumbnailName.length - thumbinailSuffix.length);
}

function fileExtension(fileName) {
	return fileName.split('.').pop();
}

function fileTitle(thumbnailName) {
	return thumbnailName.substr(thumbnailName.length - thumbinailSuffix.length + 1).substr(0, thumbinailSuffix.length - 8);
}