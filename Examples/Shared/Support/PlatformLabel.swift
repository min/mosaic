#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

#if canImport(UIKit)

/// `UILabel` already has the shape `StatCell` wants.
typealias PlatformLabel = UILabel

extension UIColor {
    static var secondaryLabelColorCompat: UIColor {
        .secondaryLabel
    }
}

#else

/// A non-editable `NSTextField` configured to behave like a label, exposing
/// `text` so call sites match UIKit.
final class PlatformLabel: NSTextField {
    var text: String? {
        get { stringValue }
        set { stringValue = newValue ?? "" }
    }

    convenience init() {
        self.init(frame: .zero)
        isEditable = false
        isSelectable = false
        isBezeled = false
        drawsBackground = false
        lineBreakMode = .byTruncatingTail
    }
}

extension NSColor {
    static var secondaryLabelColorCompat: NSColor {
        .secondaryLabelColor
    }
}

#endif
