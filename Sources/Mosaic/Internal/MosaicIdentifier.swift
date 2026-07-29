import Foundation

/// Internal identifier wrapper that satisfies `Sendable` requirements for
/// diffable data sources while still allowing callers to pass `AnyHashable`
/// values into the Mosaic APIs.
@_spi(MosaicTesting)
public struct MosaicIdentifier: Hashable, @unchecked Sendable {
    private let rawValue: AnyHashable

    public init(_ rawValue: AnyHashable) {
        self.rawValue = rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public var anyHashable: AnyHashable {
        rawValue
    }

    public var sectionItemIdentifier: SectionItemIdentifier? {
        rawValue.base as? SectionItemIdentifier
    }
}

@_spi(MosaicTesting)
public struct SectionItemIdentifier: Hashable {
    public let sectionId: AnyHashable
    public let itemId: AnyHashable

    public init(sectionId: AnyHashable, itemId: AnyHashable) {
        self.sectionId = sectionId
        self.itemId = itemId
    }
}
