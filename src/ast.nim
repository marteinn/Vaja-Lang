import tables
import hashes
from sequtils import map
from strutils import join
from token import Token

type
  NodeType* = enum
    NTIntegerLiteral,
    NTFloatLiteral,
    NTBoolean,
    NTNil,
    NTExpressionStatement,
    NTPrefixExpression,
    NTInfixExpression,
    NTIdentifier,
    NTStringLiteral,
    NTProgram
    NTAssignStatement,
    NTFunctionLiteral,
    NTBlockStatement,
    NTCallExpression,
    NTReturnStatement,
    NTPipeLR,
    NTIfExpression,
    NTCaseExpression,
    NTArrayLiteral,
    NTHashMapLiteral,
  Node* = ref object
    token*: Token
    case nodeType*: NodeType
      of NTIntegerLiteral: intValue*: int
      of NTFloatLiteral: floatValue*: float
      of NTBoolean: boolValue*: bool
      of NTNil: discard
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
      of NTPipeLR:
        pipeLeft*: Node
        pipeRight*: Node
      of NTIfExpression:
        ifCondition*: Node
        ifConsequence*: Node
        ifAlternative*: Node
      of NTCaseExpression:
        caseCondition*: Node
        casePatterns*: seq[CasePattern]
      of NTArrayLiteral: arrayElements*: seq[Node]
      of NTHashMapLiteral: hashMapElements*: OrderedTable[Node, Node]
  CasePattern* = tuple[condition: Node, consequence: Node]

method toCode*(node: Node): string {.base.} =
  return case node.nodeType:
    of NTIntegerLiteral: $node.intValue
    of NTFLoatLiteral: $node.floatValue
    of NTBoolean: $node.boolValue
    of NTNil: "nil"
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
    of NTPipeLR:
      # TODO: Fix issue where already specified args does not appear
      var pipeLeftCode: string
      if node.pipeLeft.nodeType != NTCallExpression:
        pipeLeftCode = "(" & node.pipeLeft.toCode() & ")"
      else:
        pipeLeftCode = node.pipeLeft.toCode()

      node.pipeRight.callFunction.toCode() & pipeLeftCode
    of NTIfExpression:
      if node.ifAlternative != nil:
        "if (" & node.ifCondition.toCode() & ") " & node.ifConsequence.toCode() & " else " & node.ifAlternative.toCode() & " end"
      else:
        "if (" & node.ifCondition.toCode() & ") " & node.ifConsequence.toCode() & " end"
    of NTCaseExpression:
      let nodeCode: seq[string] = map(
        node.casePatterns,
        proc (x: CasePattern): string = "of " &
          toCode(x.condition) &
          " -> " &
          toCode(x.consequence)
      )
      "case (" & node.caseCondition.toCode() & ")\n" & join(nodeCode, "\n") & "\nend"
    of NTArrayLiteral:
      let elementsCode = map(
        node.arrayElements, proc (x: Node): string = toCode(x)
      )
      "[" & join(elementsCode, ", ") & "]"
    of NTHashMapLiteral:
      var elementsCode: string = ""
      for key, val in node.hashMapElements:
        if elementsCode != "":
          elementsCode = elementsCode & ", "
        elementsCode = elementsCode & key.toCode() & ": " & val.toCode()

      "{" & elementsCode & "}"

proc hash*(node: Node): Hash =
  var h: Hash = 0
  h = h !& hash(node.nodeType)
  let nodeHash = case node.nodeType:
    of NTStringLiteral: hash(node.strValue)
    of NTIdentifier: hash(node.identValue)
    else: hash("")
  h = h !& nodeHash
  return !$h

proc newIntegerLiteral*(token: Token, intValue: int): Node =
  return Node(nodeType: NodeType.NTIntegerLiteral, intValue: intValue)

proc newFloatLiteral*(token: Token, floatValue: float): Node =
  return Node(nodeType: NodeType.NTFloatLiteral, floatValue: floatValue)

proc newNil*(token: Token): Node =
  return Node(nodeType: NodeType.NTNil)

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

proc newPipeLR*(token: Token, pipeLeft: Node, pipeRight: Node): Node =
  return Node(
    token: token,
    nodeType: NodeType.NTPipeLR,
    pipeLeft: pipeLeft,
    pipeRight: pipeRight
  )

proc newIfExpression*(
  token: Token, ifCondition: Node, ifConsequence: Node, ifAlternative: Node
): Node =
  return Node(
    nodeType: NTIfExpression,
    token: token,
    ifCondition: ifCondition,
    ifConsequence: ifConsequence,
    ifAlternative: ifAlternative
  )

proc newCaseExpression*(
  token: Token,
  caseCondition: Node,
  casePatterns: seq[CasePattern]
): Node =
  return Node(
    nodeType: NodeType.NTCaseExpression,
    token: token,
    caseCondition: caseCondition,
    casePatterns: casePatterns
  )

proc newArrayLiteral*(
  token: Token,
  arrayElements: seq[Node]
): Node =
  return Node(
    nodeType: NodeType.NTArrayLiteral,
    token: token,
    arrayElements: arrayElements
  )

proc newHashMapLiteral*(
  token: Token,
  hashMapElements: OrderedTable[Node, Node]
): Node =
  return Node(
    nodeType: NodeType.NTHashMapLiteral,
    token: token,
    hashMapElements: hashMapElements
  )

proc newProgram*(statements: seq[Node]): Node =
  return Node(nodeType: NodeType.NTProgram, statements: statements)
