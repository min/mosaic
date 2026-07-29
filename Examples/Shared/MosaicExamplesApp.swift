import SwiftUI

/// One SwiftUI app shell for both platforms. `NavigationSplitView` renders as a
/// sidebar on macOS and as a push navigation stack on iOS, so the gallery needs
/// no per-platform code.
@main
struct MosaicExamplesApp: App {
    var body: some Scene {
        WindowGroup {
            GalleryView()
            #if os(macOS)
                .frame(minWidth: 760, minHeight: 520)
            #endif
        }
        #if os(macOS)
        .windowToolbarStyle(.unified)
        #endif
    }
}

/// The examples, in the order they appear in the sidebar.
enum Example: String, CaseIterable, Identifiable, Hashable {
    case feed
    case shelves
    case list
    case layouts
    case decorations
    case capabilities

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .feed: "Feed"
        case .shelves: "Shelves"
        case .list: "List"
        case .layouts: "Layouts"
        case .decorations: "Decorations"
        case .capabilities: "Capabilities"
        }
    }

    var symbol: String {
        switch self {
        case .feed: "square.grid.2x2"
        case .shelves: "rectangle.split.3x1"
        case .list: "list.bullet"
        case .layouts: "square.on.square.dashed"
        case .decorations: "paintbrush"
        case .capabilities: "checklist"
        }
    }

    @ViewBuilder
    var screen: some View {
        switch self {
        case .feed: FeedExample()
        case .shelves: ShelvesExample()
        case .list: ListExample()
        case .layouts: LayoutGalleryExample()
        case .decorations: DecorationsExample()
        case .capabilities: CapabilitiesExample()
        }
    }
}

struct GalleryView: View {
    @State private var selection: Example? = .feed

    var body: some View {
        NavigationSplitView {
            List(Example.allCases, selection: $selection) { example in
                NavigationLink(value: example) {
                    Label(example.title, systemImage: example.symbol)
                }
            }
            .navigationTitle("Mosaic")
            #if os(macOS)
                .listStyle(.sidebar)
            #endif
        } detail: {
            if let selection {
                selection.screen
                    .id(selection)
            } else {
                Text("Select an example")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
