from token import Token
type
  NodeType* = enum
    NTIntegerLiteral,
    NTExpressionStatement,
    NTPrefixExpression,
  Node* = ref object
    token*: Token
    case nodeType*: NodeType
      of NTIntegerLiteral: value*: int
      of NTExpressionStatement: expression*: Node
      of NTPrefixExpression:
        right*: Node
        operator*: string
  Program* = ref object
    statements*: seq[Node]

method toCode*(node: Node): string =
  return case node.nodeType:
    of NTIntegerLiteral: $node.value
    of NTExpressionStatement:
      if node.expression != nil: node.expression.toCode() else: ""
    of NTPrefixExpression:
      if len(node.operator) == 1:
        "(" & node.operator & node.right.toCode() & ")"
      else:
        "(" & node.operator & " " & node.right.toCode() & ")"

proc newIntegerLiteral*(token: Token, value: int): Node =
  return Node(nodeType: NodeType.NTIntegerLiteral, value: value)

proc newExpressionStatement*(token: Token, expression: Node): Node =
  return Node(
    nodeType: NodeType.NTExpressionStatement,
    token: token,
    expression: expression
  )

proc newPrefixExpression*(token: Token, right: Node, operator: string): Node =
  return Node(
    nodeType: NodeType.NTPrefixExpression,
    token: token,
    right: right,
    operator: operator
  )

proc newProgram*(statements: seq[Node]): Program =
  return Program(statements: statements)
