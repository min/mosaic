#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Pairs a decoration element kind with the view class that renders it.
///
/// Apply to a layout with `MosaicLayout.decorated(by:)`; Mosaic registers the
/// class with the compositional layout on first use and inserts a background
/// decoration item for the element kind.
public struct MosaicDecorationRegistration: Hashable {
    public let elementKind: String
    public let viewClass: MosaicReusableView.Type

    public init(elementKind: String, viewClass: MosaicReusableView.Type) {
        self.elementKind = elementKind
        self.viewClass = viewClass
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(elementKind)
        hasher.combine(ObjectIdentifier(viewClass))
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.elementKind == rhs.elementKind
            && ObjectIdentifier(lhs.viewClass) == ObjectIdentifier(rhs.viewClass)
    }
}
