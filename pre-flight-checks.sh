#!/bin/bash

ERRORS=()

###
# Check that site can be built.
###

echo " *** Checking that site can be built."

wok --serve >/dev/null 2>&1 &
WOK_PID=$!

if [[ $? -eq 0 ]]; then
	echo " *** Site built ok."
else
	echo " *** Site could not be built."
	exit 1
fi

###
# Wait for server to start.
###

sleep 5
curl "http://localhost:8000" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
	echo " *** Server is not running."
	exit 1
fi

###
# Check that no links are broken.
###

echo " *** Checking that no links are broken."

linkchecker --no-status --no-warnings --check-extern "http://localhost:8000"

if [[ $? -ne 0 ]]; then
	ERRORS+=("Broken links found on site")
fi

###
# Check that name of conference is spelt correctly.
###

echo " *** Checking that conference name is spelt correctly"

grep -e "Pycon UK" -e "pycon UK" -e "pyconUK" -e "PyConUK" --line-number --recursive --include "*.html" output

if [[ $? -eq 0 ]]; then
	ERRORS+=("Conference name is not spelt correctly")
fi

###
# Check that output directory is checked in.
###

if [[ $TRAVIS = "true" ]]; then
	echo " *** Checking that output directory has been checked in."
	# This is required, otherwise the test for git diff's exit code never fails...
	git status

	git diff --quiet output
	if [[ $? -ne 0 ]]; then
		ERRORS+=("Uncommitted changes in output directory")
	fi
fi

kill $WOK_PID

if [[ ${#ERRORS[@]} -eq 0 ]]; then
	echo " *** All pre-flight checks passed!"
	exit 0
else
	echo " *** The following pre-flight check(s) failed:"
	for error in "${ERRORS[@]}"; do
		echo " - $error"
	done
	exit 1
fi
