//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftBasicFormat
import SwiftSyntax

/// A format style for files generated by CodeGeneration.
public class CodeGenerationFormat: BasicFormat {
  public override var indentation: TriviaPiece { .spaces(indentationLevel * 2) }

  public func ensuringTwoLeadingNewlines<NodeType: SyntaxProtocol>(node: NodeType) -> NodeType {
    if node.leadingTrivia?.first?.isNewline ?? false {
      return node.with(\.leadingTrivia, indentedNewline + (node.leadingTrivia ?? []))
    } else {
      return node.with(\.leadingTrivia, indentedNewline + indentedNewline + (node.leadingTrivia ?? []))
    }
  }

  public override func visit(_ node: MemberDeclListItemSyntax) -> MemberDeclListItemSyntax {
    let formatted = super.visit(node)
    if node.indexInParent != 0 {
      return ensuringTwoLeadingNewlines(node: formatted)
    } else {
      return formatted
    }
  }

  public override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
    if node.parent?.parent?.is(SourceFileSyntax.self) == true, !node.item.is(ImportDeclSyntax.self) {
      let formatted = super.visit(node)
      return ensuringTwoLeadingNewlines(node: formatted)
    } else {
      return super.visit(node)
    }
  }
}
