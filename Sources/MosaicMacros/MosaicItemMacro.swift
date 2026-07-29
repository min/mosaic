import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MosaicMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MosaicItemMacro.self,
    ]
}

/// Implements `@MosaicItem` and `@MosaicListItem` (declared in the `Mosaic`
/// module): inspects the attached struct or class, determines how it renders a
/// value, and emits matching `static func mosaicItem(...)` factories.
public struct MosaicItemMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let macroKind = macroKind(attribute: node)

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return try expandStructMacro(
                node: node,
                macroKind: macroKind,
                structDecl: structDecl,
                context: context
            )
        }

        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return try expandClassMacro(
                node: node,
                macroKind: macroKind,
                classDecl: classDecl,
                context: context
            )
        }

        context.diagnose(
            Diagnostic(
                node: Syntax(declaration),
                message: MosaicItemDiagnostic.message(
                    "\(macroName(attribute: node)) can only be attached to a struct or class."
                )
            )
        )
        return []
    }
}

private func expandStructMacro(
    node: AttributeSyntax,
    macroKind: MosaicMacroKind,
    structDecl: StructDeclSyntax,
    context: some MacroExpansionContext
) throws -> [DeclSyntax] {
    guard let valueType = valueType(structDeclaration: structDecl) else {
        context.diagnose(
            Diagnostic(
                node: Syntax(structDecl),
                message: MosaicItemDiagnostic.message(missingStructValueMessage(attribute: node))
            )
        )
        return []
    }

    guard let configuration = parseConfiguration(
        from: node,
        macroKind: macroKind,
        declarationKind: .swiftUIView,
        attachedTypeName: structDecl.name.text,
        context: context
    ) else {
        return []
    }
    let accessModifier = accessModifier(structDeclaration: structDecl)

    return [DeclSyntax(stringLiteral: declarationSource(
        configuration: configuration,
        valueType: valueType,
        accessModifier: accessModifier
    ))]
}

private func expandClassMacro(
    node: AttributeSyntax,
    macroKind: MosaicMacroKind,
    classDecl: ClassDeclSyntax,
    context: some MacroExpansionContext
) throws -> [DeclSyntax] {
    guard
        let classContext = validatedClassContext(
            node: node,
            macroKind: macroKind,
            classDecl: classDecl,
            context: context
        ) else
    {
        return []
    }

    let declarationKind: MosaicDeclarationKind = switch (classContext.classKind, macroKind) {
    case (.listCell, _):
        .uiKitListCell
    case (.cell, _):
        .uiKitCell
    case (.view, .item):
        .uiKitView
    case (.view, .listItem):
        .uiKitListView
    }

    guard let configuration = parseConfiguration(
        from: node,
        macroKind: macroKind,
        declarationKind: declarationKind,
        attachedTypeName: classDecl.name.text,
        context: context
    ) else {
        return []
    }
    let accessModifier = accessModifier(classDeclaration: classDecl)

    return [DeclSyntax(stringLiteral: declarationSource(
        configuration: configuration,
        valueType: classContext.valueType,
        accessModifier: accessModifier
    ))]
}

private struct ValidatedClassContext {
    let classKind: MosaicClassKind
    let valueType: String
}

private func validatedClassContext(
    node: AttributeSyntax,
    macroKind: MosaicMacroKind,
    classDecl: ClassDeclSyntax,
    context: some MacroExpansionContext
) -> ValidatedClassContext? {
    guard let classKind = classKind(classDeclaration: classDecl) else {
        context.diagnose(
            Diagnostic(
                node: Syntax(classDecl),
                message: MosaicItemDiagnostic.message(invalidClassMessage(attribute: node))
            )
        )
        return nil
    }

    guard isCompatible(macroKind: macroKind, classKind: classKind) else {
        context.diagnose(
            Diagnostic(
                node: Syntax(classDecl),
                message: MosaicItemDiagnostic.message(
                    incompatibleClassMessage(macroKind: macroKind, classKind: classKind)
                )
            )
        )
        return nil
    }

    guard let valueType = classValueType(classDeclaration: classDecl) else {
        context.diagnose(
            Diagnostic(
                node: Syntax(classDecl),
                message: MosaicItemDiagnostic.message(missingClassValueMessage(attribute: node))
            )
        )
        return nil
    }

    guard hasRenderMethod(classDeclaration: classDecl, valueType: valueType) else {
        context.diagnose(
            Diagnostic(
                node: Syntax(classDecl),
                message: MosaicItemDiagnostic.message(missingRenderMessage(attribute: node))
            )
        )
        return nil
    }

    return ValidatedClassContext(classKind: classKind, valueType: valueType)
}
