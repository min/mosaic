# Contributing

Issues and pull requests are welcome.

## Development

```sh
swift build
swift test    # macOS, native

# iOS
xcodebuild test -scheme Mosaic \
  -destination 'platform=iOS Simulator,name=<any installed iPhone simulator>'
```

## Before opening a PR

- `swiftformat .` and `swiftlint --strict` must both pass clean — CI enforces
  both. Configuration lives in `.swiftformat` / `.swiftlint.yml`.
- Add or update tests for behavior changes. Cross-platform behavior belongs in
  shared tests; UIKit-only behavior goes behind `#if canImport(UIKit)`.
- Anything that behaves differently on macOS than iOS should be reflected in
  `MosaicPlatformCapabilities` and called out in the README's *Platform
  differences* section.
- Public API needs doc comments.

## Design ground rules

- One public API surface for both platforms. Platform divergence is expressed
  as accepted-but-inert behavior plus a capability flag — not parallel `#if`
  APIs at call sites.
- Item identity (diffing) and refresh state (reconfiguration) stay separate
  concepts; don't merge them.
- Cells are never torn down for a content-only change.
