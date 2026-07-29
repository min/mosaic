import SwiftDiagnostics
import SwiftSyntax

func declarationSource(
    configuration: MosaicItemMacroConfiguration,
    valueType: String,
    accessModifier: String
) -> String {
    switch configuration {
    case .hosted:
        hostedDeclarationSource(valueType: valueType, accessModifier: accessModifier)
    case .hostedList:
        hostedListDeclarationSource(valueType: valueType, accessModifier: accessModifier)
    case .uiKitCell(let typeName):
        uiKitCellDeclarationSource(
            typeName: typeName,
            valueType: valueType,
            accessModifier: accessModifier
        )
    case .uiKitListCell(let typeName):
        uiKitListCellDeclarationSource(
            typeName: typeName,
            valueType: valueType,
            accessModifier: accessModifier
        )
    case .uiKitWrappedView(let typeName):
        wrappedCollectionViewDeclarationSource(
            typeName: typeName,
            valueType: valueType,
            accessModifier: accessModifier
        )
    case .uiKitWrappedListView(let typeName):
        wrappedListViewDeclarationSource(
            typeName: typeName,
            valueType: valueType,
            accessModifier: accessModifier
        )
    case .customCell(let typeName, let expression):
        swiftUICustomCellDeclarationSource(
            typeName: typeName,
            expression: expression,
            valueType: valueType,
            accessModifier: accessModifier
        )
    case .listCell(let typeName, let expression):
        swiftUIListCellDeclarationSource(
            typeName: typeName,
            expression: expression,
            valueType: valueType,
            accessModifier: accessModifier
        )
    }
}

func uiKitCellDeclarationSource(
    typeName: String,
    valueType: String,
    accessModifier: String
) -> String {
    uiKitDeclarationSource(
        factory: "MosaicItem.cell",
        typeName: typeName,
        valueType: valueType,
        accessModifier: accessModifier
    )
}

func uiKitListCellDeclarationSource(
    typeName: String,
    valueType: String,
    accessModifier: String
) -> String {
    uiKitDeclarationSource(
        factory: "MosaicItem.list",
        typeName: typeName,
        valueType: valueType,
        accessModifier: accessModifier
    )
}

func wrappedCollectionViewDeclarationSource(
    typeName: String,
    valueType: String,
    accessModifier: String
) -> String {
    wrappedViewDeclarationSource(
        factory: "MosaicItem.cell",
        wrapperType: "MosaicCollectionViewHostedViewCell",
        typeName: typeName,
        valueType: valueType,
        accessModifier: accessModifier
    )
}

func wrappedListViewDeclarationSource(
    typeName: String,
    valueType: String,
    accessModifier: String
) -> String {
    wrappedViewDeclarationSource(
        factory: "MosaicItem.list",
        wrapperType: "MosaicCollectionViewHostedListCell",
        typeName: typeName,
        valueType: valueType,
        accessModifier: accessModifier
    )
}

func uiKitDeclarationSource(
    factory: String,
    typeName: String,
    valueType: String,
    accessModifier: String
) -> String {
    """
    \(accessModifier)static func mosaicItem(
        id: AnyHashable,
        value: \(valueType)
    ) -> TypedMosaicItem<\(typeName), \(valueType)> {
        \(factory)(\(typeName).self, id: id, value) { cell, value in
            cell.render(value: value)
        }
    }

    \(accessModifier)static func mosaicItem(
        _ value: \(valueType)
    ) -> TypedMosaicItem<\(typeName), \(valueType)> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
    """
}

func wrappedViewDeclarationSource(
    factory: String,
    wrapperType: String,
    typeName: String,
    valueType: String,
    accessModifier: String
) -> String {
    """
    \(accessModifier)static func mosaicItem(
        id: AnyHashable,
        value: \(valueType)
    ) -> TypedMosaicItem<\(wrapperType)<\(typeName)>, \(valueType)> {
        \(factory)(\(wrapperType)<\(typeName)>.self, id: id, value) { cell, value in
            cell.hostedView.render(value: value)
        }
    }

    \(accessModifier)static func mosaicItem(
        _ value: \(valueType)
    ) -> TypedMosaicItem<\(wrapperType)<\(typeName)>, \(valueType)> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
    """
}

func hostedDeclarationSource(
    valueType: String,
    accessModifier: String
) -> String {
    """
    \(accessModifier)static func mosaicItem(
        id: AnyHashable,
        value: \(valueType)
    ) -> TypedMosaicItem<MosaicCollectionViewCell<Self>, \(valueType)> {
        MosaicItem.cell(
            MosaicCollectionViewCell<Self>.self,
            id: id,
            value,
            content: Self.init(value:)
        )
    }

    \(accessModifier)static func mosaicItem(
        _ value: \(valueType)
    ) -> TypedMosaicItem<MosaicCollectionViewCell<Self>, \(valueType)> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
    """
}

func hostedListDeclarationSource(
    valueType: String,
    accessModifier: String
) -> String {
    """
    \(accessModifier)static func mosaicItem(
        id: AnyHashable,
        value: \(valueType)
    ) -> TypedMosaicItem<MosaicCollectionViewListCell<Self>, \(valueType)> {
        MosaicItem.list(
            MosaicCollectionViewListCell<Self>.self,
            id: id,
            value,
            content: Self.init(value:)
        )
    }

    \(accessModifier)static func mosaicItem(
        _ value: \(valueType)
    ) -> TypedMosaicItem<MosaicCollectionViewListCell<Self>, \(valueType)> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
    """
}

func configurableDeclarationSource(
    factory: String,
    typeName: String,
    expression: String,
    valueType: String,
    accessModifier: String
) -> String {
    """
    \(accessModifier)static func mosaicItem(
        id: AnyHashable,
        value: \(valueType),
        configure: @escaping @MainActor (\(typeName), \(valueType)) -> Void = { _, _ in }
    ) -> TypedMosaicItem<\(typeName), \(valueType)> {
        \(factory)(
            \(expression),
            id: id,
            value,
            configure: configure,
            content: Self.init(value:)
        )
    }

    \(accessModifier)static func mosaicItem(
        _ value: \(valueType),
        configure: @escaping @MainActor (\(typeName), \(valueType)) -> Void = { _, _ in }
    ) -> TypedMosaicItem<\(typeName), \(valueType)> {
        \(factory)(
            \(expression),
            id: MosaicItem.inferredId(value: value),
            value,
            configure: configure,
            content: Self.init(value:)
        )
    }
    """
}

func swiftUICustomCellDeclarationSource(
    typeName: String,
    expression: String,
    valueType: String,
    accessModifier: String
) -> String {
    configurableDeclarationSource(
        factory: "MosaicItem.cell",
        typeName: typeName,
        expression: expression,
        valueType: valueType,
        accessModifier: accessModifier
    )
}

func swiftUIListCellDeclarationSource(
    typeName: String,
    expression: String,
    valueType: String,
    accessModifier: String
) -> String {
    configurableDeclarationSource(
        factory: "MosaicItem.list",
        typeName: typeName,
        expression: expression,
        valueType: valueType,
        accessModifier: accessModifier
    )
}

func missingStructValueMessage(attribute: AttributeSyntax) -> String {
    """
    \(macroName(attribute: attribute)) requires a stored property named `value` \
    with an explicit type annotation for SwiftUI views.
    """
}

func missingClassValueMessage(attribute: AttributeSyntax) -> String {
    "\(macroName(attribute: attribute)) requires `typealias Value = ...` for UIKit cells."
}

func missingRenderMessage(attribute: AttributeSyntax) -> String {
    "\(macroName(attribute: attribute)) requires `func render(value: Value)` for UIKit cells."
}

func invalidClassMessage(attribute: AttributeSyntax) -> String {
    """
    \(macroName(attribute: attribute)) can only be attached to UIView,
    UICollectionViewCell, or UICollectionViewListCell subclasses.
    """
}

func incompatibleClassMessage(
    macroKind: MosaicMacroKind,
    classKind: MosaicClassKind
) -> String {
    switch (macroKind, classKind) {
    case (.item, .listCell):
        "@MosaicItem cannot be attached to a UICollectionViewListCell subclass. Use @MosaicListItem."
    case (.listItem, .cell):
        "@MosaicListItem can only be attached to a UICollectionViewListCell subclass."
    default:
        "Unsupported macro usage."
    }
}

struct MosaicItemDiagnostic: DiagnosticMessage {
    let message: String

    static func message(_ text: String) -> Self {
        Self(message: text)
    }

    var diagnosticID: MessageID {
        MessageID(domain: "MosaicItemMacro", id: message)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
