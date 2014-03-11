if [ $TRAVIS ]; then
   passwordCommand="-login_password j4K7CK4oM49ZA27y532b"
else
   passwordCommand="--live"
fi

# Clear out the integrationTestResults folder
rm -rf integrationTestResults/*

"Heyzap/Pods/Subliminal/Supporting Files/CI/subliminal-test" -workspace "Heyzap/Heyzap.xcworkspace" -sim_device 'iPhone Retina (3.5-inch)' -output integrationTestResults $passwordCommand --quiet_build