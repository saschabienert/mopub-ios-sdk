#!/bin/sh

OS_VERSION=${1-"8.4"}

echo "Using $OS_VERSION"

if hash xcpretty 2>/dev/null; then
	TEST_COMMAND="xcpretty -c"
else
	echo "Not using xcpretty. Run `gem install xcpretty` to get pretty printed xcodebuild output"
	TEST_COMMAND="tee"
fi

xcodebuild -workspace Heyzap/Heyzap.xcworkspace -scheme Ads -sdk iphonesimulator -destination platform='iOS Simulator',OS=$OS_VERSION,name='iPhone 5s' build test | eval $TEST_COMMAND; exit ${PIPESTATUS[0]}

