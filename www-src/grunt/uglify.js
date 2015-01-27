module.exports = {
  options: {
    mangle: false,
    beautify: false,
    sourceMap: false,
    sourceMapIncludeSources: true
  },
  build: {
    files: [
      {
        '../www/js/style_minified.js': [
          'bower_components/jquery/dist/jquery.js',
          'bower_components/bootstrap/dist/js/bootstrap.js',
          'js/**/*.js'
        ]
      }
    ]
  }
};
