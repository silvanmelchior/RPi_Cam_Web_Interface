// Gruntfile
module.exports = function(grunt) {
  // Plugin loading
  require('load-grunt-config')(grunt);

  // Task definition
  grunt.registerTask('default', ['less', 'uglify', 'copy']);
};
