module.exports = {
  options: {
    compress: true,  // minifying the result
    sourceMap: false,
    outputSourceFiles: false
  },
  build: {
    files: {
      "../www/css/style_minified.css":"less/app.less"
    }
  }
};
