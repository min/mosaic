import Mosaic
import SwiftUI

/// Every built-in layout in one scroll view, each section labelled, so the
/// geometry differences are visible side by side.
struct LayoutGalleryExample: View {
    var body: some View {
        MosaicHost(
            title: "Layouts",
            caption: """
            Each section below uses a different built-in layout. Note that waterfall \
            keeps rows aligned rather than staggering them. The last section shows a \
            genuinely staggered layout built with .custom.
            """,
            animate: false
        ) { _ in
            MosaicModel {
                section("grid(columns: 3)", layout: .grid(columns: 3, spacing: 8, interItemSpacing: 8), count: 6)

                section(
                    "adaptiveGrid(minItemWidth: 120)",
                    layout: .adaptiveGrid(minItemWidth: 120, spacing: 8, interItemSpacing: 8),
                    count: 6
                )

                section(
                    "waterfall(columns: 3)",
                    layout: .waterfall(columns: 3, spacing: 8, interItemSpacing: 8, estimatedHeight: 70),
                    count: 6
                )

                section(
                    "carousel(itemWidth: 140)",
                    layout: .carousel(itemWidth: .absolute(140), itemHeight: .absolute(90), spacing: 8),
                    count: 8
                )

                section(
                    "custom: staggered columns",
                    layout: .custom { size in staggeredSection(width: size.width) },
                    count: 9
                )
            }
        }
    }

    private func section(_ label: String, layout: MosaicLayout, count: Int) -> MosaicSection {
        MosaicSection(
            label,
            layout: layout.sectionHeader(height: .estimated(28)),
            header: .header(label) { title in
                Text(title)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        ) {
            for index in 0..<count {
                LayoutTile.mosaicItem(
                    LayoutTile.Tile(id: index, label: "\(index + 1)", accent: index)
                )
            }
        }
    }

    /// A genuine staggered layout, assembled from a custom group that tracks a
    /// y-offset per column and places each item in the shortest one.
    private func staggeredSection(width: CGFloat) -> NSCollectionLayoutSection {
        let columns = 3
        let spacing: CGFloat = 8
        let insets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)
        let heights: [CGFloat] = [80, 120, 64, 100, 72, 132, 88, 60, 110]

        let usable = width - insets.leading - insets.trailing - CGFloat(columns - 1) * spacing
        let columnWidth = max(1, (usable / CGFloat(columns)).rounded(.down))

        let group = NSCollectionLayoutGroup.custom(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300))
        ) { _ in
            var offsets = [CGFloat](repeating: 0, count: columns)
            return heights.map { height in
                let column = offsets.enumerated().min { $0.element < $1.element }?.offset ?? 0
                let frame = CGRect(
                    x: CGFloat(column) * (columnWidth + spacing),
                    y: offsets[column],
                    width: columnWidth,
                    height: height
                )
                offsets[column] += height + spacing
                return NSCollectionLayoutGroupCustomItem(frame: frame)
            }
        }

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = insets
        return section
    }
}
