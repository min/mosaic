import Mosaic
import SwiftUI

/// A list section with selection and swipe-to-delete, which is also the clearest
/// demonstration of an accepted-but-inert behavior: the `onDelete` call below
/// compiles identically on both platforms, but only iOS has a swipe affordance
/// to trigger it.
struct ListExample: View {
    @State private var articles = SampleData.articles(10)
    @State private var lastSelected: String?

    var body: some View {
        MosaicHost(
            title: "List",
            caption: caption,
            controls: {
                HStack(spacing: 12) {
                    Text(lastSelected ?? "No selection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button("Reset") {
                        articles = SampleData.articles(10)
                        lastSelected = nil
                    }
                    .disabled(articles.count == 10)
                }
                .padding(.top, 4)
            },
            model: { _ in
                MosaicModel {
                    MosaicSection("list", layout: .list()) {
                        for article in articles {
                            ArticleRow.mosaicItem(article)
                                .didSelectItemAt {
                                    lastSelected = "Selected: \(article.title)"
                                }
                                // Stored on every platform; invoked only where a
                                // swipe affordance exists.
                                .onDelete(title: "Delete") { value in
                                    articles.removeAll { $0.id == value.id }
                                }
                        }
                    }
                }
            }
        )
    }

    private var caption: String {
        if MosaicPlatformCapabilities.hasSwipeActions {
            """
            A list section with selection and swipe-to-delete. Swipe a row to remove it. \
            The same code runs on macOS, where the configuration is stored but never \
            invoked because NSCollectionView has no swipe affordance.
            """
        } else {
            """
            A list section with selection. The swipe-to-delete configuration in this \
            screen's source is accepted here but inert, since NSCollectionView has no \
            swipe affordance. Click a row to select it.
            """
        }
    }
}
