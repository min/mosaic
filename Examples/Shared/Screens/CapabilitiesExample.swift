import Mosaic
import SwiftUI

/// Renders `MosaicPlatformCapabilities` using `StatCell`, a hand-built cell with
/// no SwiftUI inside. Running this screen on both platforms is the quickest way
/// to see which behaviors are live where.
struct CapabilitiesExample: View {
    private var stats: [StatCell.Value] {
        [
            StatCell.Value(
                id: "list",
                caption: "List configuration",
                detail: MosaicPlatformCapabilities.hasListConfiguration
                    ? "Available: appearances, separators, accessories"
                    : "Unavailable: every list style renders plain",
                isSupported: MosaicPlatformCapabilities.hasListConfiguration
            ),
            StatCell.Value(
                id: "swipe",
                caption: "Swipe actions",
                detail: MosaicPlatformCapabilities.hasSwipeActions
                    ? "Available: configurations are delivered"
                    : "Inert: configurations are stored, never invoked",
                isSupported: MosaicPlatformCapabilities.hasSwipeActions
            ),
            StatCell.Value(
                id: "reorder",
                caption: "Interactive reordering",
                detail: MosaicPlatformCapabilities.hasInteractiveReordering
                    ? "Available: reordering handlers are wired"
                    : "Inert: handlers are stored, never invoked",
                isSupported: MosaicPlatformCapabilities.hasInteractiveReordering
            ),
            StatCell.Value(
                id: "reconfigure",
                caption: "Snapshot reconfiguration",
                detail: MosaicPlatformCapabilities.hasSnapshotReconfiguration
                    ? "Native: the snapshot reconfigures items"
                    : "Emulated: configure re-runs against the visible cell",
                isSupported: MosaicPlatformCapabilities.hasSnapshotReconfiguration
            ),
        ]
    }

    var body: some View {
        MosaicHost(
            title: "Platform capabilities",
            caption: """
            The same source on both platforms. Rows are drawn by StatCell, a plain \
            MosaicCell subclass that builds its hierarchy against mosaicContentView, \
            with no SwiftUI involved.
            """,
            animate: false
        ) { _ in
            MosaicModel {
                MosaicSection(
                    "capabilities",
                    layout: MosaicLayout
                        .grid(columns: 1, spacing: 1, itemHeight: .estimated(52))
                        .contentInsets(.init(top: 8, leading: 0, bottom: 24, trailing: 0))
                ) {
                    for stat in stats {
                        MosaicItem.cell(StatCell.self, stat) { cell, value in
                            cell.render(value: value)
                        }
                    }
                }
            }
        }
    }
}
