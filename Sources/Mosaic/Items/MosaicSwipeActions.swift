#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// A single swipe action attached to a Mosaic item.
///
/// Mosaic owns this type rather than exposing `UIContextualAction` so swipe
/// APIs compile on every platform. On iOS actions are bridged to
/// `UISwipeActionsConfiguration` and behave exactly as before. macOS has no
/// swipe affordance in `NSCollectionView`, so configured actions are stored and
/// never invoked — shared call sites need no `#if`.
public struct MosaicSwipeAction {
    /// Visual and behavioral style of an action; destructive actions are
    /// additionally wrapped to delete the item from the snapshot first.
    public enum Style: Hashable, Sendable {
        case normal
        case destructive
    }

    public let style: Style
    public let title: String?
    public let image: MosaicPlatformImage?
    public let backgroundColor: MosaicPlatformColor?

    /// Performs the action, calling the supplied completion with whether it succeeded.
    public let handler: @MainActor (@escaping (Bool) -> Void) -> Void

    public init(
        style: Style = .normal,
        title: String? = nil,
        image: MosaicPlatformImage? = nil,
        backgroundColor: MosaicPlatformColor? = nil,
        handler: @escaping @MainActor (@escaping (Bool) -> Void) -> Void
    ) {
        self.style = style
        self.title = title
        self.image = image
        self.backgroundColor = backgroundColor
        self.handler = handler
    }

    /// Returns a copy whose handler runs `perform` before the original handler.
    func precededBy(_ perform: @escaping @MainActor (@escaping () -> Void) -> Void) -> Self {
        let original = handler
        return Self(
            style: style,
            title: title,
            image: image,
            backgroundColor: backgroundColor
        ) { completion in
            perform {
                original(completion)
            }
        }
    }
}

/// A set of swipe actions for one edge of a Mosaic item.
public struct MosaicSwipeActionsConfiguration {
    public var actions: [MosaicSwipeAction]
    public var performsFirstActionWithFullSwipe: Bool

    public init(
        actions: [MosaicSwipeAction],
        performsFirstActionWithFullSwipe: Bool = true
    ) {
        self.actions = actions
        self.performsFirstActionWithFullSwipe = performsFirstActionWithFullSwipe
    }

    /// Returns a copy whose destructive actions remove the item from the
    /// data-source snapshot before running their handler.
    ///
    /// Deleting first lets the platform tear down the swipe decoration while
    /// the swipe occurrence is still active.
    func deletingBeforeDestructiveActions(
        _ delete: @escaping @MainActor (@escaping () -> Void) -> Void
    ) -> Self {
        Self(
            actions: actions.map { action in
                guard action.style == .destructive else { return action }
                return action.precededBy(delete)
            },
            performsFirstActionWithFullSwipe: performsFirstActionWithFullSwipe
        )
    }
}

#if canImport(UIKit)
extension MosaicSwipeAction {
    @MainActor
    func uiKitAction() -> UIContextualAction {
        let action = UIContextualAction(
            style: style == .destructive ? .destructive : .normal,
            title: title
        ) { _, _, completion in
            handler(completion)
        }
        action.image = image
        if let backgroundColor {
            action.backgroundColor = backgroundColor
        }
        return action
    }
}

extension MosaicSwipeActionsConfiguration {
    @MainActor
    func uiKitConfiguration() -> UISwipeActionsConfiguration {
        let configuration = UISwipeActionsConfiguration(actions: actions.map { $0.uiKitAction() })
        configuration.performsFirstActionWithFullSwipe = performsFirstActionWithFullSwipe
        return configuration
    }
}
#endif
