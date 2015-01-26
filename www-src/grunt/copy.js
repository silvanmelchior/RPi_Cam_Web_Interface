module.exports = {
	build: {
        files: [
            //copy bootstrap fonts
            {
                expand: true,
                flatten: true,
                cwd: 'bower_components/bootstrap/dist/fonts/',
                src: '**',
                dest: '../www/fonts/'
            }
        ]
    }
};