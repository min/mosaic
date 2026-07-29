import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum MosaicItemMacroConfiguration {
    case hosted
    case hostedList
    case uiKitCell(typeName: String)
    case uiKitListCell(typeName: String)
    case uiKitWrappedView(typeName: String)
    case uiKitWrappedListView(typeName: String)
    case customCell(typeName: String, expression: String)
    case listCell(typeName: String, expression: String)
}

enum MosaicMacroKind: Equatable {
    case item
    case listItem
}

enum MosaicDeclarationKind {
    case swiftUIView
    case uiKitCell
    case uiKitListCell
    case uiKitView
    case uiKitListView
}

enum MosaicClassKind {
    case cell
    case listCell
    case view
}

func parseConfiguration(
    from node: AttributeSyntax,
    macroKind: MosaicMacroKind,
    declarationKind: MosaicDeclarationKind,
    attachedTypeName: String,
    context: some MacroExpansionContext
) -> MosaicItemMacroConfiguration? {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
        return defaultConfiguration(
            macroKind: macroKind,
            declarationKind: declarationKind,
            attachedTypeName: attachedTypeName
        )
    }

    var configuredCell: String?

    for argument in arguments {
        let expression = argument.expression.trimmedDescription
        switch argument.label?.text {
        case nil, "cell":
            configuredCell = expression
        default:
            diagnoseUnsupportedArgument(
                kind: macroKind,
                declarationKind: declarationKind,
                argument: argument,
                context: context
            )
            return nil
        }
    }

    switch macroKind {
    case .item:
        return itemConfiguration(
            configuredCell: configuredCell,
            declarationKind: declarationKind,
            attachedTypeName: attachedTypeName,
            node: node,
            context: context
        )
    case .listItem:
        return listConfiguration(
            configuredCell: configuredCell,
            declarationKind: declarationKind,
            attachedTypeName: attachedTypeName,
            node: node,
            context: context
        )
    }
}

func valueType(structDeclaration: StructDeclSyntax) -> String? {
    for member in structDeclaration.memberBlock.members {
        guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
        guard variable.bindings.count == 1 else { continue }
        guard let binding = variable.bindings.first else { continue }
        guard binding.accessorBlock == nil else { continue }
        guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
        guard identifier.identifier.text == "value" else { continue }
        guard let typeAnnotation = binding.typeAnnotation else { continue }
        return typeAnnotation.type.trimmedDescription
    }

    return nil
}

func accessModifier(structDeclaration: StructDeclSyntax) -> String {
    accessModifier(modifiers: structDeclaration.modifiers)
}

func accessModifier(classDeclaration: ClassDeclSyntax) -> String {
    accessModifier(modifiers: classDeclaration.modifiers)
}

func accessModifier(modifiers: DeclModifierListSyntax) -> String {
    for modifier in modifiers {
        switch modifier.name.text {
        case "public", "package":
            return modifier.name.text + " "
        default:
            continue
        }
    }
    return ""
}

func classKind(classDeclaration: ClassDeclSyntax) -> MosaicClassKind? {
    guard let inheritanceClause = classDeclaration.inheritanceClause else {
        return nil
    }

    for inheritedType in inheritanceClause.inheritedTypes {
        switch inheritedType.type.trimmedDescription {
        case "UICollectionViewListCell":
            return .listCell
        case "UICollectionViewCell":
            return .cell
        case "UIView":
            return .view
        default:
            continue
        }
    }
    return nil
}

func classValueType(classDeclaration: ClassDeclSyntax) -> String? {
    for member in classDeclaration.memberBlock.members {
        guard let typeAlias = member.decl.as(TypeAliasDeclSyntax.self) else { continue }
        guard typeAlias.name.text == "Value" else { continue }
        return typeAlias.initializer.value.trimmedDescription
    }
    return nil
}

func hasRenderMethod(classDeclaration: ClassDeclSyntax, valueType: String) -> Bool {
    for member in classDeclaration.memberBlock.members {
        guard let function = member.decl.as(FunctionDeclSyntax.self) else { continue }
        guard function.name.text == "render" else { continue }
        guard let parameter = function.signature.parameterClause.parameters.first else { continue }
        guard function.signature.parameterClause.parameters.count == 1 else { continue }
        guard parameter.firstName.text == "value" else { continue }
        let parameterType = parameter.type.trimmedDescription
        if parameterType == valueType || parameterType == "Value" {
            return true
        }
    }
    return false
}

func isCompatible(macroKind: MosaicMacroKind, classKind: MosaicClassKind) -> Bool {
    switch (macroKind, classKind) {
    case (.item, .cell), (.item, .view), (.listItem, .listCell), (.listItem, .view):
        true
    default:
        false
    }
}

func typeName(expression: String) -> String {
    if let stripped = expression.split(separator: ".", omittingEmptySubsequences: false).last,
       stripped == "self",
       expression.hasSuffix(".self")
    {
        return String(expression.dropLast(".self".count))
    }
    return expression
}

func macroKind(attribute: AttributeSyntax) -> MosaicMacroKind {
    switch macroName(attribute: attribute) {
    case "MosaicListItem":
        .listItem
    default:
        .item
    }
}

func macroName(attribute: AttributeSyntax) -> String {
    attribute.attributeName.trimmedDescription
}

func defaultConfiguration(
    macroKind: MosaicMacroKind,
    declarationKind: MosaicDeclarationKind,
    attachedTypeName: String
) -> MosaicItemMacroConfiguration? {
    switch (macroKind, declarationKind) {
    case (.item, .swiftUIView):
        .hosted
    case (.item, .uiKitCell):
        .uiKitCell(typeName: attachedTypeName)
    case (.item, .uiKitView):
        .uiKitWrappedView(typeName: attachedTypeName)
    case (.listItem, .swiftUIView):
        .hostedList
    case (.listItem, .uiKitListCell):
        .uiKitListCell(typeName: attachedTypeName)
    case (.listItem, .uiKitListView):
        .uiKitWrappedListView(typeName: attachedTypeName)
    case (.item, .uiKitListCell), (.listItem, .uiKitCell), (.item, .uiKitListView), (.listItem, .uiKitView):
        nil
    }
}

func diagnoseUnsupportedArgument(
    kind: MosaicMacroKind,
    declarationKind: MosaicDeclarationKind,
    argument: LabeledExprSyntax,
    context: some MacroExpansionContext
) {
    let message: String = switch (kind, declarationKind) {
    case (.item, .swiftUIView), (.listItem, .swiftUIView):
        kind == .item
            ? "@MosaicItem only supports a `cell:` argument."
            : "@MosaicListItem only supports a `cell:` argument."
    case (.item, .uiKitCell), (.item, .uiKitView), (.listItem, .uiKitListCell), (.listItem, .uiKitListView):
        kind == .item
            ? "@MosaicItem does not take arguments when attached to a UIKit class."
            : "@MosaicListItem does not take arguments when attached to a UIKit class."
    case (.item, .uiKitListCell), (.listItem, .uiKitCell), (.item, .uiKitListView), (.listItem, .uiKitView):
        "Unsupported macro usage."
    }

    context.diagnose(
        Diagnostic(
            node: Syntax(argument),
            message: MosaicItemDiagnostic.message(message)
        )
    )
}

func itemConfiguration(
    configuredCell: String?,
    declarationKind: MosaicDeclarationKind,
    attachedTypeName: String,
    node: AttributeSyntax,
    context: some MacroExpansionContext
) -> MosaicItemMacroConfiguration? {
    switch declarationKind {
    case .swiftUIView:
        guard let configuredCell else {
            return .hosted
        }
        return .customCell(
            typeName: typeName(expression: configuredCell),
            expression: configuredCell
        )
    case .uiKitCell:
        guard configuredCell == nil else {
            diagnoseArgumentsNotAllowed(
                kind: .item,
                declarationKind: declarationKind,
                node: node,
                context: context
            )
            return nil
        }
        return .uiKitCell(typeName: attachedTypeName)
    case .uiKitView:
        guard configuredCell == nil else {
            diagnoseArgumentsNotAllowed(
                kind: .item,
                declarationKind: declarationKind,
                node: node,
                context: context
            )
            return nil
        }
        return .uiKitWrappedView(typeName: attachedTypeName)
    case .uiKitListCell:
        return defaultConfiguration(
            macroKind: .item,
            declarationKind: declarationKind,
            attachedTypeName: attachedTypeName
        )
    case .uiKitListView:
        return defaultConfiguration(
            macroKind: .item,
            declarationKind: declarationKind,
            attachedTypeName: attachedTypeName
        )
    }
}

func listConfiguration(
    configuredCell: String?,
    declarationKind: MosaicDeclarationKind,
    attachedTypeName: String,
    node: AttributeSyntax,
    context: some MacroExpansionContext
) -> MosaicItemMacroConfiguration? {
    switch declarationKind {
    case .swiftUIView:
        guard let configuredCell else {
            return .hostedList
        }
        return .listCell(
            typeName: typeName(expression: configuredCell),
            expression: configuredCell
        )
    case .uiKitListCell:
        guard configuredCell == nil else {
            diagnoseArgumentsNotAllowed(
                kind: .listItem,
                declarationKind: declarationKind,
                node: node,
                context: context
            )
            return nil
        }
        return .uiKitListCell(typeName: attachedTypeName)
    case .uiKitListView:
        guard configuredCell == nil else {
            diagnoseArgumentsNotAllowed(
                kind: .listItem,
                declarationKind: declarationKind,
                node: node,
                context: context
            )
            return nil
        }
        return .uiKitWrappedListView(typeName: attachedTypeName)
    case .uiKitCell:
        return defaultConfiguration(
            macroKind: .listItem,
            declarationKind: declarationKind,
            attachedTypeName: attachedTypeName
        )
    case .uiKitView:
        return defaultConfiguration(
            macroKind: .listItem,
            declarationKind: declarationKind,
            attachedTypeName: attachedTypeName
        )
    }
}

func diagnoseArgumentsNotAllowed(
    kind: MosaicMacroKind,
    declarationKind: MosaicDeclarationKind,
    node: AttributeSyntax,
    context: some MacroExpansionContext
) {
    let message = switch (kind, declarationKind) {
    case (.item, .uiKitCell), (.item, .uiKitView):
        "@MosaicItem does not take arguments when attached to a UIKit class."
    case (.listItem, .uiKitListCell), (.listItem, .uiKitListView):
        "@MosaicListItem does not take arguments when attached to a UIKit class."
    default:
        "Unsupported macro usage."
    }

    context.diagnose(
        Diagnostic(
            node: Syntax(node),
            message: MosaicItemDiagnostic.message(message)
        )
    )
}
