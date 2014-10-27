module.exports = {
	options: {
		compress: true,  //minifying the result
		sourceMap: false,
		outputSourceFiles: false
	},
	build: {
		files: {
			"../www/css/app.css":"less/app.less"
		}
	}
};