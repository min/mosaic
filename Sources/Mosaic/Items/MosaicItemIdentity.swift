import Foundation

public extension MosaicItem {
    /// The identity Mosaic derives for a value when none is given explicitly:
    /// `Identifiable.id` when the value is `Identifiable`, otherwise the whole
    /// hashable value.
    ///
    /// Macro-generated `mosaicItem(_:)` helpers call this, so hand-written
    /// factories can match their identity behavior exactly.
    static func inferredId(value: some Hashable) -> AnyHashable {
        if let identifiable = value as? any Identifiable {
            return identifiable.anyMosaicIdentifier
        }
        return AnyHashable(value)
    }
}

private extension Identifiable {
    var anyMosaicIdentifier: AnyHashable {
        AnyHashable(id)
    }
}
