# Mosaic examples

A gallery app demonstrating Mosaic, built from **one shared source tree** that runs on
both platforms. Every screen in `Shared/` compiles unchanged for iOS and macOS, which
is the point: the examples are also the proof that the cross-platform promise holds.

```sh
open Examples/MosaicExamples.xcodeproj
```

Then run either scheme:

| Scheme | Destination |
| --- | --- |
| `MosaicExamples-iOS` | iOS Simulator or device |
| `MosaicExamples-macOS` | My Mac |

The project is committed so it opens without extra tooling. It is generated from
`project.yml`, so after changing the spec or adding files, regenerate it:

```sh
brew install xcodegen        # once
cd Examples && xcodegen generate
```

## What each screen shows

| Screen | Demonstrates |
| --- | --- |
| **Feed** | `adaptiveGrid` deriving its column count from the builder's width, a section header, and diffing: shuffle to see items move rather than reload, since identity is stable |
| **Shelves** | Orthogonal sections, each scrolling horizontally inside one vertically scrolling collection view |
| **List** | `list` layout with selection and swipe-to-delete. The clearest look at accepted-but-inert behavior: identical source, but macOS has no swipe affordance |
| **Layouts** | Every built-in layout side by side, plus a genuine staggered layout assembled with `.custom` |
| **Decorations** | Section backgrounds drawn by a decoration view, and headers pinned to the visible bounds |
| **Capabilities** | `MosaicPlatformCapabilities` rendered by `StatCell`, a hand-built cell with no SwiftUI inside |

## Notes on the code

- `ArticleCard`, `ArticleRow`, and `LayoutTile` use `@MosaicItem`, so the section DSL
  takes a value directly with no hand-written factory.
- `Article` conforms to `MosaicRefreshable` and deliberately leaves `readCount` out of
  its refresh projection. Shuffling bumps that field on every article, and no cell
  reconfigures as a result.
- `StatCell` builds its hierarchy against `mosaicContentView`, the cross-platform
  accessor for a cell's content container. Only its initializer is platform-specific,
  because `NSCollectionViewItem` is a view controller that loads its view separately.
- `PlatformLabel` in `Shared/Support` is a small `UILabel`/`NSTextField` shim. It is
  example scaffolding, not something Mosaic provides.
- The app shell is a single SwiftUI `App` using `NavigationSplitView`, which renders as
  a sidebar on macOS and a navigation stack on iOS.
