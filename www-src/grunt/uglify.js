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
          'node_modules/jquery/dist/jquery.js',
          'node_modules/bootstrap/dist/js/bootstrap.js'
        ]
      }
    ]
  }
};
