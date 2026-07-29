import Foundation
import Mosaic

/// The sample value rendered throughout the gallery.
///
/// `MosaicRefreshable` splits identity from rendered state: `id` drives diffing,
/// while `mosaicRefreshValue` covers only what a cell actually draws. `readCount`
/// changes constantly in `SampleData.shuffled()` but is deliberately excluded, so
/// those changes never cause a reconfiguration.
struct Article: Hashable, Identifiable, MosaicRefreshable {
    let id: Int
    let title: String
    let category: String
    let readCount: Int
    let accent: Int

    var mosaicRefreshValue: some Hashable {
        [title, category]
    }
}

enum SampleData {
    static let categories = ["Design", "Engineering", "Research", "Culture"]

    static let titles = [
        "Compositional layouts from first principles",
        "Diffing without tearing down cells",
        "A shared vocabulary for UIKit and AppKit",
        "Identity is not the same as content",
        "Prefetching that respects the scrollback",
        "Orthogonal sections in practice",
        "Reuse pools and hosted SwiftUI",
        "Estimated heights, measured twice",
        "Decorations as section backgrounds",
        "The cost of a reload you did not need",
        "Boundary items that pin",
        "One model, two frameworks",
    ]

    static func articles(_ count: Int = 12) -> [Article] {
        (0..<count).map { index in
            Article(
                id: index,
                title: titles[index % titles.count],
                category: categories[index % categories.count],
                readCount: (index * 37) % 900,
                accent: index % 6
            )
        }
    }

    /// Reorders and edits the sample set so the gallery can demonstrate moves,
    /// in-place reconfiguration, and inserts against a stable identity.
    static func shuffled(_ articles: [Article]) -> [Article] {
        articles.enumerated().map { offset, article in
            Article(
                id: article.id,
                title: offset.isMultiple(of: 3) ? "Revised: \(article.title)" : article.title,
                category: article.category,
                // Excluded from the refresh projection, so this alone never
                // triggers a reconfiguration.
                readCount: article.readCount + 1,
                accent: article.accent
            )
        }
        .shuffled()
    }
}
