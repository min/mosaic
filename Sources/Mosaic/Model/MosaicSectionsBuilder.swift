/// Result builder for constructing an array of `MosaicSection` objects.
@resultBuilder
public enum MosaicSectionsBuilder {
    public static func buildBlock(_ components: [MosaicSection]...) -> [MosaicSection] {
        components.flatMap(\.self)
    }

    public static func buildEither(first component: [MosaicSection]) -> [MosaicSection] {
        component
    }

    public static func buildEither(second component: [MosaicSection]) -> [MosaicSection] {
        component
    }

    public static func buildOptional(_ component: [MosaicSection]?) -> [MosaicSection] {
        component ?? []
    }

    public static func buildArray(_ components: [[MosaicSection]]) -> [MosaicSection] {
        components.flatMap(\.self)
    }

    public static func buildExpression(_ expression: MosaicSection) -> [MosaicSection] {
        [expression]
    }

    public static func buildLimitedAvailability(_ component: [MosaicSection]) -> [MosaicSection] {
        component
    }
}
