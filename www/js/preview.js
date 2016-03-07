/*global thumbnails,previewWidth,linksBase,mediaBase*/
var thumbinailSuffix = '.v0000.th.jpg';

function load_preview(thumbnail) {
	var prevButton = document.getElementsByName('prev')[0];
	var nextButton = document.getElementsByName('next')[0];
	var mediaDiv = document.getElementById('media');
	var title = document.getElementById('media-title');

	title.innerHTML = fileTitle(thumbnail);

	var prev, next;
	var imageIndex = thumbnails.indexOf(thumbnail);
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