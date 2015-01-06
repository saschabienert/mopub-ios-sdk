#!/bin/sh

# Clear out the integrationTestResults folder
rm -rf integrationTestResults/*

"Heyzap/Pods/Subliminal/Supporting Files/CI/subliminal-test" -workspace "Heyzap/Heyzap.xcworkspace" -sim_device 'iPhone 5' -output integrationTestResults --quiet_build