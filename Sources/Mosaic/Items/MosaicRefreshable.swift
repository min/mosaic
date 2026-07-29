/// A value that separates its *identity* from its *rendered state*.
///
/// Mosaic uses identity (`Identifiable.id`) for diffing — deciding whether an
/// item moved, appeared, or disappeared — and `mosaicRefreshValue` only to
/// decide whether an existing cell needs reconfiguration. Project into the
/// refresh value exactly the fields the cell renders: nothing that changes
/// pixels may be left out, and transport metadata or unrelated domain state
/// should not be pulled in.
///
/// ```swift
/// struct Article: Hashable, Identifiable, MosaicRefreshable {
///     let id: Int
///     let title: String
///     let fetchedAt: Date          // not rendered → not in the projection
///
///     var mosaicRefreshValue: String { title }
/// }
/// ```
///
/// Conforming values can be passed to `MosaicItem.cell(_:_:configure:)` and the
/// hosted-SwiftUI overloads without an explicit `refreshOn:` argument.
public protocol MosaicRefreshable: Hashable, Identifiable {
    associatedtype MosaicRefreshValue: Hashable

    /// A projection of only the state this value's cell renders.
    var mosaicRefreshValue: MosaicRefreshValue { get }
}
