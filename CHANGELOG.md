# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com), and versions follow
[Semantic Versioning](https://semver.org).

## [Unreleased]

## [0.1.0] (unreleased)

Initial release.

- Declarative `MosaicModel` / `MosaicSection` / `MosaicItem` DSL over
  compositional collection views, with diffing by stable identity and in-place
  reconfiguration driven by `contentHash`.
- One API surface for `UICollectionView` (iOS 17+) and `NSCollectionView`
  (macOS 14+); UIKit-only behaviors (swipe actions, list configuration,
  interactive reordering) compile everywhere and are inert on macOS, queryable
  via `MosaicPlatformCapabilities`.
- Built-in layouts (`list`, `grid`, `adaptiveGrid`, `waterfall`, `carousel`,
  `custom`) plus a compositional group/item DSL and layout modifiers.
- Typed item factories with lifecycle, selection, prefetch, and swipe-action
  callbacks; SwiftUI content hosting in any cell; header/footer/decoration
  support.
- `@MosaicItem` / `@MosaicListItem` member macros generating `mosaicItem(...)`
  factories for cells, platform views, and SwiftUI views.
- `MosaicViewRepresentable` SwiftUI wrapper with width-aware model building.
