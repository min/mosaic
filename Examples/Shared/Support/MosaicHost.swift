import Mosaic
import SwiftUI

/// Wraps `MosaicViewRepresentable` with the chrome every screen in the gallery
/// wants: a title, an explanatory caption, and a button that applies a mutated
/// model so diffing is visible.
struct MosaicHost<Controls: View>: View {
    let title: String
    let caption: String
    var animate: Bool = true
    @ViewBuilder var controls: Controls
    let model: (CGFloat) -> MosaicModel

    @State private var refreshToken = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(caption)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                controls
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            MosaicViewRepresentable(
                animate: animate,
                refreshToken: refreshToken,
                modelBuilder: model
            )
        }
        // Changing the token makes SwiftUI re-run the update pass, which
        // rebuilds and re-applies the model.
        .onChange(of: title) { refreshToken += 1 }
    }
}

extension MosaicHost where Controls == EmptyView {
    init(
        title: String,
        caption: String,
        animate: Bool = true,
        model: @escaping (CGFloat) -> MosaicModel
    ) {
        self.init(
            title: title,
            caption: caption,
            animate: animate,
            controls: { EmptyView() },
            model: model
        )
    }
}
