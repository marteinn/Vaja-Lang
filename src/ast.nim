from sequtils import map
from strutils import join
from token import Token

type
  NodeType* = enum
    NTIntegerLiteral,
    NTExpressionStatement,
    NTPrefixExpression,
    NTInfixExpression,
    NTIdentifier,
    NTBoolean,
    NTStringLiteral,
    NTProgram
  Node* = ref object
    token*: Token
    case nodeType*: NodeType
      of NTIntegerLiteral: intValue*: int
      of NTBoolean: boolValue*: bool
      of NTExpressionStatement: expression*: Node
      of NTPrefixExpression:
        prefixRight*: Node
        prefixOperator*: string
      of NTInfixExpression:
        infixLeft*: Node
        infixRight*: Node
        infixOperator*: string
      of NTIdentifier: identValue*: string
      of NTStringLiteral: strValue*: string
      of NTProgram: statements*: seq[Node]

method toCode*(node: Node): string {.base.} =
  return case node.nodeType:
    of NTIntegerLiteral: $node.intValue
    of NTBoolean: $node.boolValue
    of NTExpressionStatement:
      if node.expression != nil: node.expression.toCode() else: ""
    of NTPrefixExpression:
      if len(node.prefixOperator) == 1:
        "(" & node.prefixOperator & node.prefixRight.toCode() & ")"
      else:
        "(" & node.prefixOperator & " " & node.prefixRight.toCode() & ")"
    of NTInfixExpression:
      "(" & node.infixLeft.toCode() & " " & node.infixOperator & " " &
      node.infixRight.toCode() & ")"
    of NTIdentifier: node.identValue
    of NTStringLiteral: node.strValue
    of NTProgram: 
      let nodeCode = map(node.statements, proc (x: Node): string = toCode(x))
      join(nodeCode, "\n")

proc newIntegerLiteral*(token: Token, intValue: int): Node =
  return Node(nodeType: NodeType.NTIntegerLiteral, intValue: intValue)

proc newExpressionStatement*(token: Token, expression: Node): Node =
  return Node(
    nodeType: NodeType.NTExpressionStatement,
    token: token,
    expression: expression
  )

proc newPrefixExpression*(token: Token, prefixRight: Node, prefixOperator: string): Node =
  return Node(
    nodeType: NodeType.NTPrefixExpression,
    token: token,
    prefixRight: prefixRight,
    prefixOperator: prefixOperator
  )

proc newInfixExpression*(token: Token, infixLeft: Node, infixRight: Node, infixOperator: string): Node =
  return Node(
    nodeType: NodeType.NTInfixExpression,
    token: token,
    infixLeft: infixLeft,
    infixRight: infixRight,
    infixOperator: infixOperator
  )

proc newIdentifier*(token: Token, identValue: string): Node =
  return Node(nodeType: NodeType.NTIdentifier, identValue: identValue)

proc newBoolean*(token: Token, boolValue: bool): Node =
  return Node(nodeType: NodeType.NTBoolean, boolValue: boolValue)

proc newStringLiteral*(token: Token, strValue: string): Node =
  return Node(nodeType: NodeType.NTStringLiteral, strValue: strValue)

proc newProgram*(statements: seq[Node]): Node =
  return Node(nodeType: NodeType.NTProgram, statements: statements)
