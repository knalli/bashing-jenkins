# Bashing Jenkins

A small utility collection of bash scripts for the Jenkins CI build server. Feel free to use, feel free to contribute.


# How to use
Just clone the master branch or download the files.

Each script comes with an internal help view.


# Examples

	./jenkins-job.sh getBuildNumberFor myproject lastStableBuild
	Return 42
	
	./jenkins-job.sh getBuildNumberFor myproject lastPromotedBuild 2
	Return 23
	
	./jenkins-job.sh downloadArtifact myproject 42 target/webapp.war


# More
See official Jenkins CI profile on Github: http://github.com/jenkinsci
