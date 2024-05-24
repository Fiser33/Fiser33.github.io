import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroExampleMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacroBridge: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        StringifyMacro.expansion(of: node, in: context)
    }
}

@main
struct MacroExamplePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacroBridge.self,
    ]
}
