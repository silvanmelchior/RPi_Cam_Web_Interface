module.exports = {
  build: {
    files: [
      // copy bootstrap fonts
      {
        expand: true,
        flatten: true,
        cwd: 'node_modules/bootstrap/dist/fonts/',
        src: '**',
        dest: '../www/fonts/'
      }
    ]
  }
};
