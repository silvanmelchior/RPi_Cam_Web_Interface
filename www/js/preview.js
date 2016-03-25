var SUBDIR_CHAR = "@"
var next, prev;

(function() {
	document.onkeyup = function () {
		switch (event.keyCode) {
		case 39:
		    if (next) {
		    	load_preview(next);
		    }
		    break;
		case 37:
		    if (prev) {
		    	load_preview(prev);
		    }
		    break;
		}
	};
})();

function load_preview(thumbnail) {
	var previewDiv = document.getElementById('preview');
	var prevButton = document.getElementsByName('prev')[0];
	var nextButton = document.getElementsByName('next')[0];
	var downloadButton = document.getElementsByName('download1')[0];
	var deleteButton = document.getElementsByName('delete1')[0];
	var convertDetailsDiv = document.getElementById('convert-details');
	var convertButton = document.getElementsByName('convert')[0];
	var mediaDiv = document.getElementById('media');
	var title = document.getElementById('media-title');

	previewDiv.style.display = 'block';
	history.pushState(null, null, linksBase + thumbnail);

	title.innerHTML = fileTitle(thumbnail);
	downloadButton.value = thumbnail;
	deleteButton.value = thumbnail;

	var imageIndex = thumbnails.indexOf(thumbnail);

	// Previous 
	if (imageIndex > 0) {
		prev = thumbnails[imageIndex-1];
		prevButton.disabled = false;
		prevButton.onclick = function() {
			load_preview(prev);
		}

		if (fileExtension(imageFromThumbnail(prev)) == 'jpg') {
			preloadImage(mediaBase + imageFromThumbnail(prev));
		}
	} else {
		prev = null;
		prevButton.disabled = true;
	}

	// Next
	if (imageIndex >= 0 && imageIndex < thumbnails.length-1) {
		next = thumbnails[imageIndex+1];
		nextButton.disabled = false;
		nextButton.onclick = function() {
			load_preview(next);
		}

		if (fileExtension(imageFromThumbnail(next)) == 'jpg') {
			preloadImage(mediaBase + imageFromThumbnail(next));
		}
	} else {
		next = null;
		nextButton.disabled = true;
	}

	var mediaURL = mediaBase + imageFromThumbnail(thumbnail);
	if (mediaURL) {
		var media_content;
		if (fileExtension(mediaURL) == 'jpg') {
			media_content = '<a href="' + mediaURL + '" target="_blank"><img src="' + mediaURL + '" style="width: ' + previewWidth + 'px;"></a>';
		} else {
			media_content = '<video style="width:' + previewWidth + 'px;" controls><source src="' + mediaURL + '" type="video/mp4">Your browser does not support the video tag.</video>';
		}

		mediaDiv.innerHTML = media_content;
	}

	if (fileType(thumbnail) == 't') {
		convertDetailsDiv.style.display = 'inline';
		convertButton.style.display = 'inline';
		convertButton.value = thumbnail;
	} else {
		convertDetailsDiv.style.display = 'none';
		convertButton.style.display = 'none';
		convertButton.value = '';
	}
}

function suffixLength(thumbnail) {
   return thumbnail.length - thumbnail.lastIndexOf(".", thumbnail.length - 8);
}

function imageFromThumbnail(thumbnailName) {
	var temp = thumbnailName.substr(0, thumbnailName.length - suffixLength(thumbnailName));
   return temp.split(SUBDIR_CHAR).join("/");
}

function fileExtension(fileName) {
	return fileName.split('.').pop();
}

function fileType(fileName) {
	var suffix = fileName.substr(-suffixLength(fileName));
	return suffix.substr(1, 1);
}

function fileTitle(thumbnailName) {
	return thumbnailName.substr(thumbnailName.length - suffixLength(thumbnailName) + 1).substr(0, suffixLength(thumbnailName) - 8);
}

function preloadImage(url) {
    var _img = new Image();
    _img.src = url;
}

function getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}
