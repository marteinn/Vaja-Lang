from sequtils import map
from strutils import join
from token import Token

type
  NodeType* = enum
    NTIntegerLiteral,
    NTFloatLiteral,
    NTExpressionStatement,
    NTPrefixExpression,
    NTInfixExpression,
    NTIdentifier,
    NTBoolean,
    NTStringLiteral,
    NTProgram
    NTAssignStatement,
    NTFunctionLiteral,
    NTBlockStatement,
    NTCallExpression,
    NTReturnStatement
    NTPipe
  Node* = ref object
    token*: Token
    case nodeType*: NodeType
      of NTIntegerLiteral: intValue*: int
      of NTFloatLiteral: floatValue*: float
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
      of NTAssignStatement:
        assignName*: Node
        assignValue*: Node
      of NTFunctionLiteral:
        functionBody*: Node
        functionParams*: seq[Node]
        functionName*: Node
      of NTBlockStatement: blockStatements*: seq[Node]
      of NTCallExpression:
        callFunction*: Node
        callArguments*: seq[Node]
      of NTReturnStatement:
        returnValue*: Node
      of NTPipe:
        pipeLeft*: Node
        pipeRight*: Node

method toCode*(node: Node): string {.base.} =
  return case node.nodeType:
    of NTIntegerLiteral: $node.intValue
    of NTFLoatLiteral: $node.floatValue
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
    of NTAssignStatement:
      "let " & node.assignName.identValue & " = " & toCode(node.assignValue)
    of NTFunctionLiteral:
      let
        paramsCode: seq[string] = map(node.functionParams, proc (x: Node): string = toCode(x))
        paramsCodeString: string = join(paramsCode, ", ")
      if node.functionName != nil:
        "fn " & node.functionName.identValue & "(" & paramsCodeString & ") " & node.functionBody.toCode() & " end"
      else:
        "fn" & "(" & paramsCodeString & ") " & node.functionBody.toCode() & " end"

    of NTBlockStatement:
      let nodeCode = map(node.blockStatements, proc (x: Node): string = toCode(x))
      join(nodeCode, "\n")
    of NTCallExpression:
      let argumentsCode = map(
        node.callArguments, proc (x: Node): string = toCode(x)
      )
      node.callFunction.toCode() & "(" & join(argumentsCode, ", ") & ")"
    of NTReturnStatement:
      "return " & toCode(node.returnValue)
    of NTPipe:
      var pipeLeftCode: string
      if node.pipeLeft.nodeType != NTCallExpression:
        pipeLeftCode = "(" & node.pipeLeft.toCode() & ")"
      else:
        pipeLeftCode = node.pipeLeft.toCode()

      node.pipeRight.callFunction.toCode() & pipeLeftCode

proc newIntegerLiteral*(token: Token, intValue: int): Node =
  return Node(nodeType: NodeType.NTIntegerLiteral, intValue: intValue)

proc newFloatLiteral*(token: Token, floatValue: float): Node =
  return Node(nodeType: NodeType.NTFloatLiteral, floatValue: floatValue)

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

proc newAssignStatement*(token: Token, assignName: Node, assignValue: Node): Node =
  return Node(
    nodeType: NodeType.NTAssignStatement,
    token: token,
    assignName: assignName,
    assignValue: assignValue
  )

proc newFuntionLiteral*(
  token: Token,
  functionBody: Node,
  functionParams: seq[Node],
  functionName: Node
): Node =
  return Node(
    nodeType: NodeType.NTFunctionLiteral,
    token: token,
    functionBody: functionBody,
    functionParams: functionParams,
    functionName: functionName
  )

proc newBlockStatement*(token: Token, blockStatements: seq[Node]): Node =
  return Node(
    token: token,
    nodeType: NodeType.NTBlockStatement,
    blockStatements: blockStatements
  )

proc newCallExpression*(token: Token, callFunction: Node, callArguments: seq[Node]): Node =
  return Node(
    nodeType: NodeType.NTCallExpression,
    token: token,
    callFunction: callFunction,
    callArguments: callArguments
  )

proc newReturnStatement*(token: Token, returnValue: Node): Node =
  return Node(
    token: token, nodeType: NodeType.NTReturnStatement, returnValue: returnValue
  )

proc newPipe*(token: Token, pipeLeft: Node, pipeRight: Node): Node =
  return Node(
    token: token,
    nodeType: NodeType.NTPipe,
    pipeLeft: pipeLeft,
    pipeRight: pipeRight
  )

proc newProgram*(statements: seq[Node]): Node =
  return Node(nodeType: NodeType.NTProgram, statements: statements)
