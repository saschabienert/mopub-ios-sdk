** 3rd party SDKs have been moved to Cocoapods **

I've started vendoring 3rd party mediation SDKs using Cocoapods. Delete any local frameworks you have in this folder and run `pod install` to install them for the mediation project.

Reasoning

a) Keeps repo size down. We're up to 82 MB of 3rd party SDKs. Since we keep adding more networks + we need new binaries when ad networks update their SDKs, we'll build up a big git repo. Don't want a repeat of mobile-sdk.
b) Keeps everyone on consistent versions. This is especially important for CI but also good for devs.
c) Make it easy for devs to get the 3rd party SDKs.

It actually turned out to be really easy to do as well. 3 of the ad networks have Cocoapods for their latest versions, one has a tagged git repo perfect for Cocoapods use, and the remaining two I get from the zip files by using http (rather than git) for the pod source.

Currently the Cocoapods source repo is under Max's github account, just while I'm testing.
