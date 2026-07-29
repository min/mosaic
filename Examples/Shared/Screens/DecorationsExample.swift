#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import Mosaic
import SwiftUI

/// A section background drawn behind the items by a decoration view, plus a
/// pinned header. Both are compositional-layout features with no SwiftUI
/// equivalent.
struct DecorationsExample: View {
    private let articles = SampleData.articles(9)

    private static let background = MosaicDecorationRegistration(
        elementKind: "section-background",
        viewClass: SectionBackgroundView.self
    )

    /// Result builders cannot contain `guard`/`continue`, so empty categories are
    /// filtered out before the model is built.
    private var groupedByCategory: [(String, [Article])] {
        SampleData.categories.compactMap { category in
            let items = articles.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        MosaicHost(
            title: "Decorations",
            caption: """
            Each section sits on a rounded background supplied by a decoration view, \
            registered once with the layout. The headers pin to the top of the visible \
            bounds as you scroll.
            """,
            animate: false
        ) { _ in
            MosaicModel {
                for (category, items) in groupedByCategory {
                    MosaicSection(
                        "decorated-\(category)",
                        layout: MosaicLayout
                            .grid(columns: 2, spacing: 10, interItemSpacing: 10)
                            .contentInsets(.init(top: 44, leading: 16, bottom: 16, trailing: 16))
                            .sectionHeader(height: .absolute(36), pinToVisibleBounds: true)
                            .decorated(by: Self.background),
                        header: .header(category) { title in
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    ) {
                        for article in items {
                            ArticleCard.mosaicItem(article)
                        }
                    }
                }
            }
        }
    }
}

/// The decoration view itself: a plain platform view, so it compiles on both
/// platforms with only the initializer differing.
private final class SectionBackgroundView: MosaicReusableView {
    #if canImport(UIKit)
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .quaternarySystemFill
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #else
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.12).cgColor
        layer?.cornerRadius = 18
        layer?.cornerCurve = .continuous
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #endif
}
