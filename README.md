<p align="center">
  <img src="Assets/logo.svg" alt="" width="112">
</p>

<h1 align="center">Mosaic</h1>

<p align="center"><b>Declarative compositional collection views for iOS and macOS.</b></p>

<p align="center">
  <a href="https://github.com/min/mosaic/actions/workflows/ci.yml"><img src="https://github.com/min/mosaic/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/Swift-6.0-orange" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B-blue" alt="Platforms">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License: MIT"></a>
</p>

You describe a model of sections and items. Mosaic owns the collection view, the
diffable data source, and the diffing. Items are identified by a stable `id` and
re-rendered **in place** when their `contentHash` changes, so a cell is never torn
down just because its content changed. One API surface backs `UICollectionView` on
iOS and `NSCollectionView` on macOS, and the model, layout DSL, and item callbacks
compile unchanged on both.

## Why Mosaic?

Reach for it when you want collection view behavior that SwiftUI's `List` and
`LazyVGrid` don't expose, without giving up a declarative model:

- **Compositional layouts.** Orthogonal sections, custom groups, pinned boundary
  items, decorations, and anything else `NSCollectionLayoutSection` can express.
- **An explicit identity and refresh contract.** Stable IDs drive the diffing, and a
  projection of exactly the state a cell renders drives reconfiguration.
- **Cell reuse you control.** Real cells, prefetching hooks, lifecycle callbacks, and
  SwiftUI content hosted inside any of them.
- **One codebase, two platforms.** The same feed, grid, or browser runs on UIKit
  and AppKit.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/min/mosaic", from: "0.1.0")
]
```

```swift
.target(name: "MyApp", dependencies: ["Mosaic"])
```

## Getting started

Start with a value and a cell that renders it:

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

`MosaicView` is a plain `UIView` on iOS and a plain `NSView` on macOS. Add it to a
view controller and call `apply(_:animate:)` whenever your data changes.

### From SwiftUI

`MosaicViewRepresentable` wraps the same view. Its builder receives the current width
so layouts can adapt:

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

## Core concepts

### Identity vs. refresh

Identity decides how items are diffed. `contentHash` decides whether a visible cell
needs reconfiguring. Keep the two separate: conform to `MosaicRefreshable` and project
only the fields the cell actually renders.

```swift
struct Article: Hashable, Identifiable, MosaicRefreshable {
    let id: Int
    let title: String
    let fetchedAt: Date          // not rendered, so not in the projection

    var mosaicRefreshValue: String { title }
}

MosaicItem.cell(ArticleCell.self, article)   // identity + refresh derived from the value
```

Use the explicit `refreshOn:` overload when refresh state also comes from captured
context such as selection or presentation mode.

### Layouts

| Layout | Shape |
| --- | --- |
| `.list(style:)` | Rows. List appearances and swipe actions on iOS, a plain compositional list on macOS |
| `.grid(columns:itemHeight:)` | Fixed column count, uniform item height |
| `.adaptiveGrid(minItemWidth:)` | Column count derived from the available width |
| `.waterfall(columns:estimatedHeight:)` | Equal-width columns with estimated heights. Rows stay aligned rather than staggered |
| `.carousel(itemHeight:behavior:)` | Horizontally scrolling section with paging behaviors |
| `.custom(_:)` / `MosaicLayout.section { ... }` | Anything compositional layout can express |

Layouts refine with `contentInsets`, `interGroupSpacing`, `orthogonalScrollingBehavior`,
`sectionHeader`/`sectionFooter`, and `decorated(by:)`. A raw
`NSCollectionLayoutSection` drops in directly via `MosaicLayout(_:)`.

### Item callbacks

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

### Headers, footers, and decorations

A section carries at most one supplementary view per element kind. The layout supplies
the boundary item and the section supplies the view:

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
`apply`. Section backgrounds register through `MosaicDecorationRegistration` and
`layout.decorated(by:)`.

## One API, two platforms

Platform types are reached through aliases, so a cell written against
`UICollectionViewCell` on iOS already satisfies `MosaicCell`:

| Mosaic | iOS | macOS |
| --- | --- | --- |
| `MosaicCell`, `MosaicListCell` | `UICollectionViewCell`, `UICollectionViewListCell` | `NSCollectionViewItem` subclass |
| `MosaicReusableView` | `UICollectionReusableView` | `NSView & NSCollectionViewElement` |
| `MosaicPlatformView` / `Color` / `Image` | `UIView` / `UIColor` / `UIImage` | `NSView` / `NSColor` / `NSImage` |
| `MosaicCollectionView` | `UICollectionView` | `NSCollectionView` (in `MosaicView.scrollView`) |
| `MosaicViewRepresentable` | `UIViewRepresentable` | `NSViewRepresentable` |

The whole `NSCollectionLayout*` family and diffable data sources exist on both
platforms, so layouts, decorations, supplementary views, and prefetching behave
identically.

A few UIKit behaviors have no AppKit counterpart. Rather than splitting the API,
Mosaic accepts them everywhere and leaves them inert on macOS, so shared call sites
need no `#if`. Query them through `MosaicPlatformCapabilities`:

- **Swipe actions.** `NSCollectionView` has no swipe affordance, so `onDelete(_:)` and
  the leading/trailing swipe configurations are stored but never invoked.
- **List configuration.** There is no `UICollectionLayoutListConfiguration`, so every
  `MosaicListStyle` renders as a plain compositional list and `MosaicListCell` is the
  same type as `MosaicCell` (no separators or accessories).
- **Interactive reordering.** `NSCollectionViewDiffableDataSource` has no
  `reorderingHandlers`, so `canReorderSectionItem` and `onSectionItemsReordered` are
  stored but never invoked.
- **`contentInsetAdjustmentBehavior`.** `NSScrollView` has no equivalent, so the value
  is ignored.
- **Snapshot reconfiguration.** AppKit has no `reconfigureItems`, so Mosaic re-runs
  the item's `configure` closure against the visible cell instead. The observable
  contract is the same: the cell updates in place and is never torn down.

Two smaller notes. AppKit loads an item's view lazily, so the hosted cells force the
load at init to match UIKit's lifecycle. SwiftUI content is hosted through
`UIHostingConfiguration` on iOS and through `NSHostingView` on macOS.

## Development

```sh
swift test    # macOS, native

xcodebuild test -scheme Mosaic \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'   # any installed simulator
```

UIKit-only behavior (swipe delivery, list content configuration, accessories) is
covered by tests behind `#if canImport(UIKit)`. Everything else runs on both
platforms. See [CONTRIBUTING.md](CONTRIBUTING.md) for the repository layout, style
rules, and design ground rules.

## License

MIT. See [LICENSE](LICENSE).
