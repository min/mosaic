import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// A supplementary view that hosts SwiftUI `Content`.
///
/// iOS hosts through a `UIHostingController`; macOS through an `NSHostingView`,
/// which needs no parent view controller. Either way the hosting view is
/// created once and its root view updated on later calls, so SwiftUI state
/// survives reconfiguration.
public final class MosaicCollectionReusableView<Content: View>: MosaicReusableView {
    #if canImport(UIKit)
    private var hostingController: UIHostingController<Content>?

    public func host(_ content: Content) {
        if let hostingController {
            hostingController.rootView = content
        } else {
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.backgroundColor = .clear
            pinHostingView(hostingController.view)
            self.hostingController = hostingController
        }
    }
    #else
    private var hostingView: NSHostingView<Content>?

    public func host(_ content: Content) {
        if let hostingView {
            hostingView.rootView = content
        } else {
            let hostingView = NSHostingView(rootView: content)
            pinHostingView(hostingView)
            self.hostingView = hostingView
        }
    }
    #endif

    private func pinHostingView(_ hostingView: MosaicPlatformView) {
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}

/// A supplementary view that hosts a platform view of type `Content`, pinned
/// to its edges. Used by the `MosaicSupplementaryView.view`/`header`/`footer`
/// factories when the hosted type is not itself a reusable view.
public final class MosaicCollectionReusableHostedView<Content: MosaicPlatformView>: MosaicReusableView {
    public let hostedView: Content

    override public init(frame: CGRect) {
        hostedView = Content(frame: .zero)
        super.init(frame: frame)
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A type-erased supplementary view (header, footer, or custom element kind)
/// attached to a `MosaicSection`.
///
/// Create one with the `header`, `footer`, or `view` factories — hosting either
/// a platform view or SwiftUI content — and pass it to the section
/// initializers. Identity is the element kind; a section carries at most one
/// supplementary view per kind. Visible supplementary views are reconfigured
/// in place whenever a new model is applied.
public struct MosaicSupplementaryView: Hashable {
    public let elementKind: String
    public let reuseIdentifier: String?
    public let value: Any
    public let viewType: MosaicReusableView.Type

    public let configure: @MainActor (MosaicReusableView, Any) -> Void

    public init(
        elementKind: String,
        viewType: MosaicReusableView.Type,
        value: Any,
        reuseIdentifier: String? = nil,
        configure: @escaping @MainActor (MosaicReusableView, Any) -> Void
    ) {
        self.elementKind = elementKind
        self.viewType = viewType
        self.value = value
        self.reuseIdentifier = reuseIdentifier
        self.configure = configure
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(elementKind)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.elementKind == rhs.elementKind
    }
}

public extension MosaicSupplementaryView {
    static func view<HostedView: MosaicPlatformView, Value: Hashable>(
        elementKind: String,
        _ viewType: HostedView.Type = HostedView.self,
        id _: AnyHashable? = nil,
        _ value: Value,
        configure: @escaping @MainActor (HostedView, Value) -> Void = { _, _ in }
    ) -> Self {
        let reusableViewType = (viewType as? MosaicReusableView.Type)
            ?? MosaicCollectionReusableHostedView<HostedView>.self

        return Self(
            elementKind: elementKind,
            viewType: reusableViewType,
            value: value
        ) { view, storedValue in
            guard let typedValue = storedValue as? Value else { return }
            if let typedView = view as? HostedView {
                configure(typedView, typedValue)
            } else if let reusableView = view as? MosaicCollectionReusableHostedView<HostedView> {
                configure(reusableView.hostedView, typedValue)
            }
        }
    }

    @MainActor
    static func header<HostedView: MosaicPlatformView, Value: Hashable>(
        _ viewType: HostedView.Type = HostedView.self,
        id: AnyHashable? = nil,
        _ value: Value,
        configure: @escaping @MainActor (HostedView, Value) -> Void = { _, _ in }
    ) -> Self {
        view(
            elementKind: MosaicCollectionView.elementKindSectionHeader,
            viewType,
            id: id,
            value,
            configure: configure
        )
    }

    @MainActor
    static func footer<HostedView: MosaicPlatformView, Value: Hashable>(
        _ viewType: HostedView.Type = HostedView.self,
        id: AnyHashable? = nil,
        _ value: Value,
        configure: @escaping @MainActor (HostedView, Value) -> Void = { _, _ in }
    ) -> Self {
        view(
            elementKind: MosaicCollectionView.elementKindSectionFooter,
            viewType,
            id: id,
            value,
            configure: configure
        )
    }

    static func view<Content: View, Value: Hashable>(
        elementKind: String,
        id _: AnyHashable? = nil,
        _ value: Value,
        @ViewBuilder content: @escaping @MainActor (Value) -> Content
    ) -> Self {
        Self(
            elementKind: elementKind,
            viewType: MosaicCollectionReusableView<Content>.self,
            value: value
        ) { view, storedValue in
            guard let reusableView = view as? MosaicCollectionReusableView<Content>,
                  let typedValue = storedValue as? Value else { return }
            reusableView.host(content(typedValue))
        }
    }

    @MainActor
    static func header<Value: Hashable>(
        id: AnyHashable? = nil,
        _ value: Value,
        @ViewBuilder content: @escaping @MainActor (Value) -> some View
    ) -> Self {
        view(
            elementKind: MosaicCollectionView.elementKindSectionHeader,
            id: id,
            value,
            content: content
        )
    }

    @MainActor
    static func footer<Value: Hashable>(
        id: AnyHashable? = nil,
        _ value: Value,
        @ViewBuilder content: @escaping @MainActor (Value) -> some View
    ) -> Self {
        view(
            elementKind: MosaicCollectionView.elementKindSectionFooter,
            id: id,
            value,
            content: content
        )
    }
}
