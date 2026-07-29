import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The cell class used by hosted-SwiftUI items created with
/// `MosaicItem.cell(_:content:)` and friends.
///
/// The `Content` type parameter keeps each SwiftUI view hierarchy in its own
/// reuse pool, so cells are only ever reused for the same kind of content.
public final class MosaicCollectionViewCell<Content: View>: MosaicCell {}
