/// A declarative model representing the entire state of a `MosaicView`.
public struct MosaicModel: Hashable {
    /// Sections in display order.
    public let sections: [MosaicSection]

    /// Initializes a model using a result-builder for sections.
    public init(@MosaicSectionsBuilder _ builder: () -> [MosaicSection]) {
        sections = builder()
    }

    /// Returns the item associated with `itemId`, if present anywhere in the model.
    public func item(itemId: AnyHashable) -> MosaicItem? {
        for section in sections {
            if let item = section.items.first(where: { $0.id == itemId }) { return item }
        }
        return nil
    }

    /// Returns the item associated with `itemId` in the specified section, if present.
    public func item(itemId: AnyHashable, sectionId: AnyHashable) -> MosaicItem? {
        sections.first(where: { $0.id == sectionId })?.items.first(where: { $0.id == itemId })
    }
}
