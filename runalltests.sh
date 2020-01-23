#!/usr/bin/bash

function unittest() {
	dub test --compiler=$1
	return $?
}

function buildConf() {
	dub --compiler=$1 --config=$2
	return $?
}

function test() {
	cd $1
	echo "TESTING: $1 with $2 PWD: $(pwd)"
	unittest $2
	local e=$?
	if [[ $e -ne 0 ]]
	then
		cd ..
		echo "FAILED: $1 unittest with compiler $2 with error code $e"
		exit $e
	fi

	for i in ${@:3} ;
	do
		buildConf $2 $i
		local f=$?
		if [[ $f -ne 0 ]]
		then
			cd ..
			echo "FAILED: $1 with compiler $2 and configuration $i, error code $f"
			exit $f
		fi
	done
	cd ..
	return 0
}

for dc in $1
do
	test utils ${dc}
	test exception ${dc}
	#test sdlang ${dc} "ExcessiveTests"
	test testdata ${dc} "app"
	test sdlang ${dc}
	test semver ${dc}
	#test pkgdescription ${dc} "ExcessiveSDLTests" "ExcessiveJSONTests" "ExcessiveConvTests"
	test pkgdescription ${dc}
	test resolve ${dc}
	test descriptiongetter ${dc}
done
exit 0
