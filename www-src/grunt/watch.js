module.exports = {
  javascript: {
    files: [
      'js/**/*.js'
    ],
    tasks: ['newer:uglify']
  },
  less: {
    files: [
      'less/**/*.less'
    ], // watched files
    tasks: ['less']
  },
  wwww: {
    files: [
      '../www/**/*.{css,js,php}'
    ],
    options: {
      livereload: true
    }
  }
};
