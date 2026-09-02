# MurtiPreviewApp

A small SwiftUI iOS app that renders a bundled `Resources/Screen.json` with Murti, so
you can preview a screen you authored — with the DSL, MurtiStudio, or by hand — on a
simulator or device.

## Run

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(the `.xcodeproj` isn't committed):

```sh
cd examples/MurtiPreviewApp
xcodegen generate
open MurtiPreviewApp.xcodeproj
```

Pick the **MurtiPreviewApp** scheme and run on **My Mac** or an iOS Simulator (⌘R).

## Use it

Replace `Resources/Screen.json` with your own payload and run again.

The app depends on the local `MurtiCore` package (`../..`) and registers one custom
component as an example of extending the built-ins: an `image` that loads a `url` (a
remote link or an embedded `data:` URL), falling back to a labelled placeholder for a
missing named asset. It also uses relaxed validation bounds so oversized preview
payloads still load; production apps keep the strict defaults.
