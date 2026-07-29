import Mosaic
import SwiftUI

/// An adaptive grid whose column count follows the available width, with a
/// section header and controls that apply a mutated model so diffing is visible.
struct FeedExample: View {
    @State private var articles = SampleData.articles(12)

    var body: some View {
        MosaicHost(
            title: "Feed",
            caption: """
            An adaptive grid: the column count is derived from the width the builder \
            receives, so resizing the window relayouts without any code. Shuffling \
            keeps identities stable, so items move instead of being replaced.
            """,
            controls: {
                HStack(spacing: 12) {
                    Button("Shuffle") {
                        articles = SampleData.shuffled(articles)
                    }
                    Button("Remove first") {
                        if !articles.isEmpty {
                            articles.removeFirst()
                        }
                    }
                    .disabled(articles.isEmpty)
                    Button("Reset") {
                        articles = SampleData.articles(12)
                    }
                }
                .padding(.top, 4)
            },
            model: { _ in
                MosaicModel {
                    MosaicSection(
                        "feed",
                        layout: MosaicLayout
                            .adaptiveGrid(minItemWidth: 180, spacing: 12, interItemSpacing: 12)
                            .sectionHeader(height: .estimated(32)),
                        header: .header("\(articles.count) articles") { title in
                            Text(title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    ) {
                        for article in articles {
                            ArticleCard.mosaicItem(article)
                        }
                    }
                }
            }
        )
    }
}
