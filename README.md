# Mosaic

[![CI](https://github.com/min/mosaic/actions/workflows/ci.yml/badge.svg)](https://github.com/min/mosaic/actions/workflows/ci.yml)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B-blue)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

A declarative DSL over compositional collection views for iOS and macOS.

Describe a model of sections and items; Mosaic owns the collection view, the diffable
data source, and the diffing. Items are identified by a stable `id` and re-rendered
**in place** when their `contentHash` changes — cells are never torn down just because
their content moved on.

One API surface backs `UICollectionView` on iOS 17+ and `NSCollectionView` on macOS 14+.
The model, layout DSL, and item callbacks compile unchanged on both.

**Why not SwiftUI `List`/`LazyVGrid`?** Mosaic is for when you want collection-view
behavior SwiftUI doesn't expose — compositional layouts (orthogonal sections, custom
groups, pinned boundary items, decorations), cell reuse you control, prefetching hooks,
and in-place reconfiguration driven by an explicit identity/refresh contract — while
still writing a declarative model and hosting SwiftUI content inside any cell.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/min/mosaic", from: "0.1.0")
]
```

```swift
.target(name: "MyApp", dependencies: ["Mosaic"])
```

## Quick start

```swift
import Mosaic

struct Article: Hashable, Identifiable {
    let id: Int
    let title: String
}

final class ArticleCell: MosaicCell {
    func render(_ article: Article) { /* ... */ }
}
```

Build a model and apply it. Sections and items support `if`, `for`, and arrays:

```swift
let model = MosaicModel {
    MosaicSection("featured", layout: .carousel(itemHeight: .absolute(180))) {
        for article in featured {
            MosaicItem.cell(ArticleCell.self, article) { cell, article in
                cell.render(article)
            }
        }
    }

    if !archive.isEmpty {
        MosaicSection("archive", layout: .grid(columns: 2)) {
            for article in archive {
                MosaicItem.cell(ArticleCell.self, article) { cell, article in
                    cell.render(article)
                }
            }
        }
    }
}

mosaicView.apply(model, animate: true)
```

`MosaicView` is a plain `UIView`/`NSView` — add it to a view controller and call
`apply(_:animate:)` whenever your data changes. From SwiftUI, use
`MosaicViewRepresentable`, whose builder receives the current width so layouts can adapt:

```swift
MosaicViewRepresentable { width in
    MosaicModel {
        MosaicSection("grid", layout: .grid(columns: width > 700 ? 3 : 2)) {
            for article in articles {
                MosaicItem.cell(article) { article in
                    Text(article.title)   // hosted SwiftUI content
                }
            }
        }
    }
}
```

### The `@MosaicItem` macro

For row types you use often, the macro generates the factory boilerplate. Attach it to
a SwiftUI view with a `value` property, a `MosaicCell` subclass with `render(value:)`,
or a plain platform view with `render(value:)`:

```swift
@MosaicItem
struct ArticleRow: View {
    let value: Article
    var body: some View { Text(value.title) }
}

MosaicSection("articles") {
    for article in articles {
        ArticleRow.mosaicItem(article)
    }
}
```

`@MosaicListItem` is the list-cell variant.

## Identity vs. refresh

Identity drives diffing; `contentHash` decides whether a visible cell needs
reconfiguring. Keep them separate — conform to `MosaicRefreshable` and project only the
fields the cell actually renders:

```swift
struct Article: Hashable, Identifiable, MosaicRefreshable {
    let id: Int
    let title: String
    let fetchedAt: Date          // not rendered → not in the projection

    var mosaicRefreshValue: String { title }
}

MosaicItem.cell(ArticleCell.self, article)   // identity + refresh derived from the value
```

Use the explicit `refreshOn:` overload when refresh state also comes from captured
context such as selection or presentation mode.

## Layouts

| Layout | Shape |
| --- | --- |
| `.list(style:)` | Rows; list appearances and swipe actions on iOS, plain compositional list on macOS |
| `.grid(columns:itemHeight:)` | Fixed column count, uniform item height |
| `.adaptiveGrid(minItemWidth:)` | Column count derived from available width |
| `.waterfall(columns:estimatedHeight:)` | Equal-width columns with estimated heights — rows stay aligned (not a staggered/masonry layout) |
| `.carousel(itemHeight:behavior:)` | Horizontally scrolling section with paging behaviors |
| `.custom(_:)` / `MosaicLayout.section { ... }` | Anything compositional layout can express |

Layouts refine with `contentInsets`, `interGroupSpacing`, `orthogonalScrollingBehavior`,
`sectionHeader`/`sectionFooter`, and `decorated(by:)`. A raw
`NSCollectionLayoutSection` drops in directly via `MosaicLayout(_:)`.

## Item callbacks

Factory results are typed, so chained callbacks receive your cell and value types:

```swift
MosaicItem.cell(ArticleCell.self, article) { cell, article in
    cell.render(article)
}
.willDisplay { cell, article in imageLoader(article) }
.prefetchItemAt { article in imageLoader(article) }
.didSelectItemAt { openDetail() }
.onDelete(title: "Remove") { article in store.delete(article) }
```

Also available: `didEndDisplaying`, `didReconfigure`, `cancelPrefetchingForItemAt`,
`shouldSelect`/`shouldDeselect`/`didDeselect`, highlight callbacks, and full
leading/trailing swipe-action configurations.

## Headers, footers, and decorations

A section carries at most one supplementary view per element kind; the layout supplies
the boundary item, the section supplies the view:

```swift
MosaicSection(
    "archive",
    layout: .grid(columns: 2).sectionHeader(),
    header: .header("Archive") { title in
        Text(title).font(.headline)
    }
) { /* items */ }
```

Supplementary views host SwiftUI (`.header { ... }`) or platform views
(`.header(HeaderView.self, ...)`), and visible ones are reconfigured in place on every
`apply`. Section backgrounds register through `MosaicDecorationRegistration` +
`layout.decorated(by:)`.

## Platform vocabulary

Platform types are reached through aliases, so a cell written against
`UICollectionViewCell` on iOS already satisfies `MosaicCell`:

| Mosaic | iOS | macOS |
| --- | --- | --- |
| `MosaicCell`, `MosaicListCell` | `UICollectionViewCell`, `UICollectionViewListCell` | `NSCollectionViewItem` subclass |
| `MosaicReusableView` | `UICollectionReusableView` | `NSView & NSCollectionViewElement` |
| `MosaicPlatformView` / `Color` / `Image` | `UIView` / `UIColor` / `UIImage` | `NSView` / `NSColor` / `NSImage` |
| `MosaicCollectionView` | `UICollectionView` | `NSCollectionView` (in `MosaicView.scrollView`) |
| `MosaicViewRepresentable` | `UIViewRepresentable` | `NSViewRepresentable` |

The whole `NSCollectionLayout*` family and diffable data sources exist on both platforms,
so layouts, decorations, supplementary views, and prefetching behave identically.

## Platform differences

A few UIKit behaviours have no AppKit counterpart. Rather than splitting the API, they
are **accepted and inert** on macOS, so shared call sites need no `#if`. Query them via
`MosaicPlatformCapabilities`:

- **Swipe actions** (`onDelete(_:)`, `leading`/`trailingSwipeActionsConfiguration`) —
  `NSCollectionView` has no swipe affordance. Configurations are stored, never invoked.
- **List configuration** — no `UICollectionLayoutListConfiguration`, so every
  `MosaicListStyle` renders as a plain compositional list, and `MosaicListCell` is just
  `MosaicCell` (no separators or accessories).
- **Interactive reordering** — `NSCollectionViewDiffableDataSource` has no
  `reorderingHandlers`, so `canReorderSectionItem` and `onSectionItemsReordered` are
  stored, never invoked.
- **`contentInsetAdjustmentBehavior`** — no `NSScrollView` equivalent; ignored.
- **Snapshot reconfiguration** — AppKit has no `reconfigureItems`, so Mosaic re-runs the
  item's `configure` against the visible cell instead. Same observable contract: updated
  in place, cell never torn down.

Two smaller notes: AppKit loads an item's view lazily, so the hosted cells force it at
init to match UIKit's lifecycle; and SwiftUI content is hosted via
`UIHostingConfiguration` on iOS and `NSHostingView` on macOS.

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
```

## Tests

```sh
swift test    # macOS, native

xcodebuild test -scheme Mosaic \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'   # any installed simulator
```

UIKit-only behaviour (swipe delivery, list content configuration, accessories) is covered
by `#if canImport(UIKit)` tests; everything else runs on both platforms.

## License

MIT — see [LICENSE](LICENSE).
