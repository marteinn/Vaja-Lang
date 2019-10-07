from token import Token
type
  NodeType* = enum
    NTIntegerLiteral,
    NTExpressionStatement,
    NTPrefixExpression,
    NTInfixExpression
    NTIdentifier
  Node* = ref object
    token*: Token
    case nodeType*: NodeType
      of NTIntegerLiteral: intValue*: int
      of NTExpressionStatement: expression*: Node
      of NTPrefixExpression:
        prefixRight*: Node
        prefixOperator*: string
      of NTInfixExpression:
        infixLeft*: Node
        infixRight*: Node
        infixOperator*: string
      of NTIdentifier: strValue*: string
  Program* = ref object
    statements*: seq[Node]

method toCode*(node: Node): string {.base.} =
  return case node.nodeType:
    of NTIntegerLiteral: $node.intValue
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
    of NTIdentifier: node.strValue

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

proc newIdentifier*(token: Token, strValue: string): Node =
  return Node(nodeType: NodeType.NTIdentifier, strValue: strValue)

proc newProgram*(statements: seq[Node]): Program =
  return Program(statements: statements)
