# Contributing

Issues and pull requests are welcome.

## Repository layout

```
Sources/Mosaic/          core library (MosaicCore)
  Model/                 MosaicModel, MosaicSection, result builders
  Items/                 MosaicItem, typed wrapper, factories, refresh, swipe actions
  Layout/                MosaicLayout, layout DSL, built-in layouts
  Cells/                 hosted cells, supplementary + decoration views
  Views/                 MosaicView, delegate conformances, SwiftUI wrapper
  Platform/              UIKit/AppKit aliases, shims, capability flags
Sources/MosaicExports/   the `Mosaic` product: re-export + macro declarations
Sources/MosaicMacros/    @MosaicItem macro implementation (swift-syntax)
Tests/MosaicTests/       cross-platform suite
Examples/                gallery app; Shared/ builds for both iOS and macOS
Assets/                  logo and other repository art (not part of any target)
```

`Examples/MosaicExamples.xcodeproj` is committed so the demo opens without extra
tooling, and it is generated from `Examples/project.yml`. After changing the spec
or adding files under `Examples/Shared`, regenerate it and commit the result:

```sh
brew install xcodegen        # once
cd Examples && xcodegen generate
```

CI builds both example schemes, so a stale project fails there rather than on
someone else's Mac.

## Development

```sh
swift build
swift test    # macOS, native

# iOS
xcodebuild test -scheme Mosaic \
  -destination 'platform=iOS Simulator,name=<any installed iPhone simulator>'
```

## Before opening a PR

- `swiftformat .` and `swiftlint --strict` must pass clean. CI enforces both,
  and configuration lives in `.swiftformat` / `.swiftlint.yml`.
- Add or update tests for behavior changes. Cross-platform behavior belongs in
  shared tests; UIKit-only behavior goes behind `#if canImport(UIKit)`.
- Anything that behaves differently on macOS than iOS should be reflected in
  `MosaicPlatformCapabilities` and called out in the README's *One API, two
  platforms* section.
- Public API needs doc comments.

## Design ground rules

- One public API surface for both platforms. Platform divergence is expressed
  as accepted-but-inert behavior plus a capability flag, not parallel `#if`
  APIs at call sites.
- Item identity (diffing) and refresh state (reconfiguration) stay separate
  concepts; don't merge them.
- Cells are never torn down for a content-only change.
