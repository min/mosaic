@_exported import MosaicCore

/// Generates `static func mosaicItem(...)` factories for a cell, view, or
/// SwiftUI view so values drop straight into the section DSL.
///
/// Attach to one of:
/// - a `MosaicCell` subclass exposing `render(value:)` — items configure the
///   cell by calling it,
/// - a plain platform view exposing `render(value:)` — the view is wrapped in
///   `MosaicCollectionViewHostedViewCell`,
/// - a SwiftUI `View` with a `let value: Value` property — content is hosted in
///   `MosaicCollectionViewCell` (or the cell type passed as `cell:`).
///
/// The generated helpers are `mosaicItem(id:value:)` and `mosaicItem(_:)`; the
/// latter infers identity via `MosaicItem.inferredId(value:)`.
///
/// ```swift
/// @MosaicItem
/// struct ArticleRow: View {
///     let value: Article
///     var body: some View { Text(value.title) }
/// }
///
/// MosaicSection("articles") {
///     for article in articles {
///         ArticleRow.mosaicItem(article)
///     }
/// }
/// ```
@attached(member, names: named(mosaicItem))
public macro MosaicItem(
    cell: Any.Type? = nil
) = #externalMacro(module: "MosaicMacros", type: "MosaicItemMacro")

/// The list-cell variant of `@MosaicItem`: generated factories dequeue list
/// cells (`MosaicListCell`), wrapping plain views in
/// `MosaicCollectionViewHostedListCell` and SwiftUI content in
/// `MosaicCollectionViewListCell`.
@attached(member, names: named(mosaicItem))
public macro MosaicListItem(
    cell: Any.Type? = nil
) = #externalMacro(module: "MosaicMacros", type: "MosaicItemMacro")
