import Mosaic
import SwiftUI

/// Horizontally scrolling shelves built from orthogonal sections, the layout
/// SwiftUI's `List` cannot express without nesting scroll views.
struct ShelvesExample: View {
    private let articles = SampleData.articles(12)

    var body: some View {
        MosaicHost(
            title: "Shelves",
            caption: """
            One section per category, each scrolling horizontally on its own via \
            orthogonalScrollingBehavior, inside a single vertically scrolling \
            collection view.
            """
        ) { _ in
            MosaicModel {
                for category in SampleData.categories {
                    let items = articles.filter { $0.category == category }

                    MosaicSection(
                        "shelf-\(category)",
                        layout: MosaicLayout
                            .carousel(
                                itemWidth: .absolute(220),
                                itemHeight: .absolute(150),
                                spacing: 12,
                                behavior: .continuousGroupLeadingBoundary
                            )
                            .sectionHeader(height: .estimated(32)),
                        header: .header(category) { title in
                            Text(title)
                                .font(.headline)
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
