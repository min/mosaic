import Mosaic
import SwiftUI

/// A SwiftUI card hosted inside a Mosaic cell.
///
/// `@MosaicItem` generates `ArticleCard.mosaicItem(_:)` and
/// `.mosaicItem(id:value:)`, so the section DSL can take the value directly
/// with no hand-written factory.
@MosaicItem
struct ArticleCard: View {
    let value: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Palette.accent(value.accent).gradient)
                .frame(height: 64)

            Text(value.category.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Palette.accent(value.accent))

            Text(value.title)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// A compact row used by the list and carousel examples.
@MosaicItem
struct ArticleRow: View {
    let value: Article

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Palette.accent(value.accent).gradient)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(value.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(value.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// A labelled tile used by the layout gallery, so each layout's geometry is
/// legible at a glance.
@MosaicItem
struct LayoutTile: View {
    let value: Tile

    struct Tile: Hashable, Identifiable {
        let id: Int
        let label: String
        let accent: Int
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Palette.accent(value.accent).gradient)
            .overlay {
                Text(value.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
    }
}
