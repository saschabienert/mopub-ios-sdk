#!/bin/bash

OS_VERSION=${1-"8.4"}
SCHEME=${2-"Ads"}

echo "Using iOS $OS_VERSION"
echo "Testing Scheme: $SCHEME"

if hash xcpretty 2>/dev/null; then
	TEST_COMMAND="xcpretty -c"
else
	echo "Not using xcpretty. Run `gem install xcpretty` to get pretty printed xcodebuild output"
	TEST_COMMAND="tee"
fi

xcodebuild -workspace Heyzap/Heyzap.xcworkspace -scheme $SCHEME -sdk iphonesimulator -destination platform='iOS Simulator',OS=$OS_VERSION,name='iPhone Retina (4-inch)' build test | eval $TEST_COMMAND; exit ${PIPESTATUS[0]}

