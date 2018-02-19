module.exports = function(grunt) {
    // Project configuration.
    grunt.initConfig({
        qunit: {
          all: {
            options: {
              urls: ['http://localhost:8000/src/test.html']
            }
          }
        },
        connect: {
          server: {
            options: {
              port: 8000,
              base: '.'
            }
          }
        }
    });

    // Load plugin
    grunt.loadNpmTasks('grunt-contrib-connect');
    grunt.loadNpmTasks('grunt-contrib-qunit');

    // Task to run tests
    grunt.registerTask('test', ['connect','qunit']);
};
