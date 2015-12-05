#!/bin/bash

OS_VERSION=${1-"8.4"}
SCHEME=${2-"Ads"}

DEFAULT_OUTPUT_DIR="/tmp/"`uuidgen`
OUTPUT_DIR=${3-$DEFAULT_OUTPUT_DIR}

echo "Using iOS $OS_VERSION"
echo "Testing Scheme: $SCHEME"
echo "Outputting results to directory: $OUTPUT_DIR"

if hash xcpretty 2>/dev/null; then
	TEST_COMMAND="xcpretty -c"
else
	echo "Not using xcpretty. Run `gem install xcpretty` to get pretty printed xcodebuild output"
	TEST_COMMAND="tee"
fi

xcodebuild -workspace Heyzap/Heyzap.xcworkspace -scheme $SCHEME -sdk iphonesimulator -destination platform='iOS Simulator',OS=$OS_VERSION,name='iPhone Retina (4-inch)' -resultBundlePath $OUTPUT_DIR build test | eval $TEST_COMMAND; EXIT_CODE=${PIPESTATUS[0]}

find "$OUTPUT_DIR" -type f -name "action.xcactivitylog" | xargs -L1 gunzip -S .xcactivitylog

exit $EXIT_CODE
