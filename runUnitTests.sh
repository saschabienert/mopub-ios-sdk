OS_VERSION=${1-"7.1"} # Default to 7.1, which Xcode 5.1 has installed by default

echo "Using $OS_VERSION"

if hash xcpretty 2>/dev/null; then
	TEST_COMMAND="xcpretty -c"
else
	echo "Not using xcpretty. Run `gem install xcpretty` to get pretty printed xcodebuild output"
	TEST_COMMAND="tee"
fi

xcodebuild -workspace Heyzap/Heyzap.xcworkspace -scheme Ads -sdk iphonesimulator$OS_VERSION -destination platform='iOS Simulator',OS=$OS_VERSION,name='iPhone Retina (4-inch)' build test | eval $TEST_COMMAND; exit ${PIPESTATUS[0]}
