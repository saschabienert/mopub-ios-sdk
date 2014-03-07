Heyzap iOS SDK
=======

Integrating the SDK
----
Heyzap is still hosting its SDK and documentation at https://developers.heyzap.com/docs. If you're looking to integrate ads, we suggest downloading our SDK rather than building from source.


Building from Source
--------------------
You may want to contribute features, fix bugs, or just poke around the source code of our SDK. To build, open the `Heyzap/Heyzap.xcworkspace` file, choose the HeyzapSDKTest target, and click run.

<img src="/DocumentationImages/chooseTarget.png" alt="Choose Target">

Support & Contributions
------
If you spot a bug, or have trouble integrating the SDK, [open an Issue on Github](https://github.com/Heyzap/ios-sdk/issues) or contact support@heyzap.com. We welcome any contributions via pull requests.

Making a Release
----------------

The SDK should be built with the latest version of XCode and the Command Line tools installed.

Making a release is unnecessary for development purposes, but you may want to build the SDK nonetheless. To do so, first install dependencies:

```
brew update
brew install ant
```
Then build the SDK:
```
./build.sh <marketing-version>
# Example: ./build.sh 6.4.0
```
This will generate 3 build products:

* `HeyzapAds.framework`, which is recommended for iOS projects showing ads
* `libHeyzap.a` (and associated headers), which is equivalent to `HeyzapAds.framework`, but is easier to integrate into 3rd party build processes (like Unity).
