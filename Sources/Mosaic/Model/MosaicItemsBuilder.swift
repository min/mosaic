/// Result builder for defining an array of `MosaicItem` objects.
@resultBuilder
public enum MosaicItemsBuilder {
    public static func buildBlock(_ components: [MosaicItem]...) -> [MosaicItem] {
        components.flatMap(\.self)
    }

    public static func buildEither(first component: [MosaicItem]) -> [MosaicItem] {
        component
    }

    public static func buildEither(second component: [MosaicItem]) -> [MosaicItem] {
        component
    }

    public static func buildOptional(_ component: [MosaicItem]?) -> [MosaicItem] {
        component ?? []
    }

    public static func buildArray(_ components: [[MosaicItem]]) -> [MosaicItem] {
        components.flatMap(\.self)
    }

    public static func buildExpression(_ expression: MosaicItem) -> [MosaicItem] {
        [expression]
    }

    public static func buildExpression(_ expression: some MosaicItemType) -> [MosaicItem] {
        [expression.mosaicItem]
    }

    public static func buildExpression(_ expression: [some MosaicItemType]) -> [MosaicItem] {
        expression.map(\.mosaicItem)
    }

    public static func buildLimitedAvailability(_ component: [MosaicItem]) -> [MosaicItem] {
        component
    }
}
