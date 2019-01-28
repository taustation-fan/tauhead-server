module.exports = function(grunt) {
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		sass: {
			dist: {
				options: {
					style: 'compressed',
					sourcemap: 'none'
				},
				files: {
					'dist/tauhead.min.css': 'tauhead.scss'
				}
			}
		},
		uglify: {
			options: {
				mangle: false
			},
			dist: {
				files: {
					'root/static/item_list.min.js': 'src/item_list.js'
				}
			}
		}
	});
	grunt.loadNpmTasks('grunt-contrib-sass');
	grunt.loadNpmTasks('grunt-contrib-uglify');
	grunt.registerTask('default',['sass', 'uglify']);
}
