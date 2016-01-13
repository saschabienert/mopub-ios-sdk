## Distributing the test app

### Enterprise Distribution Setup

1. Create an `itms-services` link that points to a `.plist` file. The `.plist` file *must* be served over HTTPS.

```html
<a href="itms-services://?action=download-manifest&url=https://example.com/app.plist">Install</a>
```

2. Setup the plist file using [this](https://gist.github.com/palaniraja/1051160) as a template. Our plist files are stored at https://heyzap.com/apps/*.plist since build.heyzap.com doesn't have HTTPS.

3. Upload a `.ipa` to the the URL given in the plist.

Useful references:

http://stackoverflow.com/a/22325916/1176156
http://dr-palaniraja.blogspot.in/2011/06/distribute-your-iphoneipad-adhoc-builds.html

### Creating the IPA

