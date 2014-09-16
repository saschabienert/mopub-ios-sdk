In an attempt to keep git repo size down, I'm seeing if we can keep the 3rd party SDKs within these folders, which are all git-ignored.

The downside to this is that the Xcodeproj file has to keep a reference to them, so you won't be able to build the Mediation Test App without dragging in the third party networks.

To add the networks, follow the [instructions from the iOS Mediation Docs](https://developers.heyzap.com/docs/ios_mediation_docs) to download the networks, then just drag in appropriate files to their designated folder.