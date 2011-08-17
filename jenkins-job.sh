#!/bin/sh

# bashing jenkins
# a small utility collection of bash scripts for jenkins ci
# created by Jan Philipp <knallisworld@googlemail.com>
# hosted on github @ https://github.com/knalli/bashing-jenkins

export BASHING_JENKINS_VERSION="0.0.2"
export LOCAL_VERBOSE="yes"
# Changelog
# 2011-08-17 State				0.0.2
# 2011-02-17 Initial Release 	0.0.1


# FUNCTIONS

function printHeader(){
	echo ""
	echo "bashing-jenkins/job v$BASHING_JENKINS_VERSION by @knalli"
}

function printHelp(){
	echo "Usage: $0 <jobName> <methodName> [<arguments>]"
	echo ""
	echo "Configuration"
	echo "	JENKINS_SERVER_URL: $JENKINS_SERVER_URL"
	echo ""
	echo "	Note: The configuration properties can be overridden by creating a jenkins-settings.sh. See jenkins-settings.sh.example."
	echo ""
	echo "Standard API: Methods"
	echo ""
	echo "	get-build-number <types>"
	echo "		types: (lastBuild|lastStableBuild|lastSuccessfulBuild|lastFailedBuild|lastUnsuccessfulBuild|lastPromotedBuild <level>)"
	echo ""
	echo "		Will return the specified build number. The type lastPromotedBuild requires an additional argument level."
	echo ""
	echo "		Examples:"
	echo "			$0 test-project get-build-number lastBuild"
	echo "			$0 test-project get-build-number lastPromotedBuild 2"
	echo ""
	echo ""
	echo "	get-build-state"
	echo "		Will return the specified build state."
	echo ""
	echo "		Examples:"
	echo "			$0 test-project get-build-state"
	echo "			$0 test-project get-build-state"
	echo ""
	echo ""
	echo "	download-artifact <buildNumber> <relativeName> [<saveAs>]"
	echo "		buildNumber: a valid build number (digits only)"
	echo "		relativeName: in general a relative path pointing to an artifact"
	echo "		saveAs: is optional. Unless saveAs is specified the download will saved in the current working directory."
	echo ""
	echo "		Will download the the specified artifact within the build number."
	echo ""
	echo "		Examples:"
	echo "			$0 test-project downloadArtifact 42 target/webapp.war"
}

function assertSystemRequirements(){
	if [[ ! -z "`which wget 2>/dev/null`" ]]
		then
		return 0
	else
		echo "Missing wget."
		return 1
	fi
}

function assertServerIsAvailable(){
	if [[ $LOCAL_VERBOSE = 'yes' ]] 
		then
		echo "TODO: Check if server is available: $JENKINS_SERVER_URL"
	fi
	return 0
}

function fetchPage(){
	# 1 url
	echo `curl "$1" 2>/dev/null`
	return 0
}

function downloadFile(){
	# 1 url, 2 saveAs (optional)
	if [[ $2 = "" ]]
		then
		wget --quiet "$1"
	else
		wget --quiet --output-document="$2" "$1"
	fi
	
	if [[ $? != 0 ]]
		then 
		return 1
	fi
	
	return 0
}

function result(){
	# 1 result
	if [[ $LOCAL_VERBOSE == 'yes' ]] 
		then 
		echo "Result: $1"
	else
		echo "$1"
	fi
}

# Return the latest build number for the specified job and (internal) type.
function getJobBuildNumberByType(){
	# 1 job name, 2 type
	echo $(fetchPage "$JENKINS_SERVER_URL/job/$1/$2/api/xml?xpath=//number/text()")
	return 0
}

# Return the latest build number for the specified job and the specified promoted level.
function getJobBuildNumberByLevel(){
	# 1 job name, 2 level
	echo $(fetchPage "$JENKINS_SERVER_URL/job/$1/api/xml?xpath=*/build[action/levelValue=$2][1]/number/text()&depth=1")
	return 0
}

# Return the file path of the downloaded artifact.
function downloadJobArtifact(){
	# 1 job name, 2 build number, 3 relative path of artifact, 4 saveAs optional
	echo $(downloadFile "$JENKINS_SERVER_URL/job/$1/$2/artifact/$3" "$4")
	return 0
}

# Return the latest build state for the specified job.
function getJobBuildState(){
	# 1 job name, 2 type
	echo $(fetchPage "$JENKINS_SERVER_URL/job/$1/$2/api/xml?xpath=/mavenModuleSetBuild/result/text()")
	return 0
}

# MAIN

# Load special settings (e.g. no enviroments set up)
if [[ -e 'jenkins-settings.sh' ]]
	then
	. ./jenkins-settings.sh
fi

# Show help
if [[ $# < 1 ]]
	then
	printHeader
	printHelp
	exit 1
fi

# Show header
if [[ $LOCAL_VERBOSE == 'yes' ]] 
	then
	printHeader
fi

assertSystemRequirements
if [[ $? != 0 ]] 
	then
	echo "Error: System requirements not complete."
	exit 1
fi
assertServerIsAvailable
if [[ $? != 0 ]] 
	then
	echo "Error: Server is not available."
	exit 1
fi

if [[ "$1" = "get-build-number" ]]
	then
	if [[ "$3" =~ (lastBuild|lastStableBuild|lastSuccessfulBuild|lastFailedBuild|lastUnsuccessfulBuild) ]]
		then
		echo $(result $(getJobBuildNumberByType "$2" "$3"))
		exit 0
	elif [[ "$3" =~ (lastPromotedBuild) ]] 
		then
		echo $(result $(getJobBuildNumberByLevel "$2" "$4"))
		exit 0
	else
		if [[ $LOCAL_SHUTUP != 'yes' ]] 
			then
			echo "Type $3 is not supported."
		fi
		exit 1
	fi
fi

if [[ "$1" = "get-build-state" ]]
	then
	if [[ "$3" =~ (lastBuild|lastStableBuild|lastSuccessfulBuild|lastFailedBuild|lastUnsuccessfulBuild) ]]
		then
		echo $(result $(getJobBuildState "$2" "$3"))
		exit 0
	else
		if [[ $LOCAL_SHUTUP != 'yes' ]] 
			then
			echo "Type $3 is not supported."
		fi
		exit 1
	fi
fi

if [[ "$1" = "download-artifact" ]]
	then
	echo $(result $(downloadJobArtifact "$2" "$3" "$4" "$5"))
fi