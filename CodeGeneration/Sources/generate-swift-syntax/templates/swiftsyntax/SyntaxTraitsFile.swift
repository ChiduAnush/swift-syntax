//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftSyntaxBuilder
import SyntaxSupport
import Utils

let syntaxTraitsFile = SourceFileSyntax(leadingTrivia: copyrightHeader) {
  for trait in TRAITS {
    try! ProtocolDeclSyntax(
      """
      // MARK: - \(trait.protocolName)

      \(trait.documentation)
      public protocol \(trait.protocolName): SyntaxProtocol
      """
    ) {
      for child in trait.children {
        let questionMark = child.isOptional ? TokenSyntax.postfixQuestionMarkToken() : nil

        DeclSyntax(
          """
          \(child.documentation)
          var \(child.varOrCaseName): \(child.syntaxNodeKind.syntaxType)\(questionMark) { get set }
          """
        )
      }
    }

    try! ExtensionDeclSyntax("public extension \(trait.protocolName)") {
      DeclSyntax(
        """
        /// Without this function, the `with` function defined on `SyntaxProtocol`
        /// does not work on existentials of this protocol type.
        @_disfavoredOverload
        func with<T>(_ keyPath: WritableKeyPath<\(trait.protocolName), T>, _ newChild: T) -> \(trait.protocolName) {
          var copy: \(trait.protocolName) = self
          copy[keyPath: keyPath] = newChild
          return copy
        }
        """
      )
    }

    try! ExtensionDeclSyntax("public extension SyntaxProtocol") {
      DeclSyntax(
        """
        /// Check whether the non-type erased version of this syntax node conforms to
        /// `\(trait.protocolName)`.
        /// Note that this will incur an existential conversion.
        func isProtocol(_: \(trait.protocolName).Protocol) -> Bool {
          return self.asProtocol(\(trait.protocolName).self) != nil
        }
        """
      )

      DeclSyntax(
        """
        /// Return the non-type erased version of this syntax node if it conforms to
        /// `\(trait.protocolName)`. Otherwise return `nil`.
        /// Note that this will incur an existential conversion.
        func asProtocol(_: \(trait.protocolName).Protocol) -> \(trait.protocolName)? {
          return Syntax(self).asProtocol(SyntaxProtocol.self) as? \(trait.protocolName)
        }
        """
      )
    }
  }

  for node in SYNTAX_NODES.compactMap(\.layoutNode) where !node.traits.isEmpty {
    DeclSyntax("extension \(node.kind.syntaxType): \(raw: node.traits.map { $0 + "Syntax" }.joined(separator: ", ")) {}")
  }
}
