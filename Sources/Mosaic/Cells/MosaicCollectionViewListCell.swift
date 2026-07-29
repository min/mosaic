import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The list-cell counterpart of `MosaicCollectionViewCell`, used by hosted
/// SwiftUI items created with `MosaicItem.list(_:content:)` and friends.
///
/// On iOS this inherits `UICollectionViewListCell` chrome (separators,
/// accessories); on macOS it is the same as a plain cell.
public final class MosaicCollectionViewListCell<Content: View>: MosaicListCell {}
