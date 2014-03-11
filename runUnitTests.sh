OS_VERSION=${1-"7.1"} # Default to 7.1, which Xcode 5.1 has installed by default

echo "Using $OS_VERSION"

xcodebuild -workspace Heyzap/Heyzap.xcworkspace -scheme Ads -sdk iphonesimulator$OS_VERSION -destination platform='iOS Simulator',OS=$OS_VERSION,name='iPhone Retina (4-inch)' build test | xcpretty -c; exit ${PIPESTATUS[0]}