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
    NTDestructAssignStatement,
    NTFunctionLiteral,
    NTBlockStatement,
    NTCallExpression,
    NTReturnStatement,
    NTPipeLR,
    NTPipeRL,
    NTFNCompositionLR,
    NTFNCompositionRL,
    NTIfExpression,
    NTCaseExpression,
    NTArrayLiteral,
    NTHashMapLiteral,
    NTIndexOperation,
    NTModule,
    NTMacroLiteral
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
      of NTDestructAssignStatement:
        destructAssignNamesAndIndexes*: seq[(Node, Node)]
        destructAssignValue*: Node
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
        pipeLRLeft*: Node
        pipeLRRight*: Node
      of NTPipeRL:
        pipeRLLeft*: Node
        pipeRLRight*: Node
      of NTFNCompositionLR:
        fnCompositionLRLeft*: Node
        fnCompositionLRRight*: Node
      of NTFNCompositionRL:
        fnCompositionRLLeft*: Node
        fnCompositionRLRight*: Node
      of NTIfExpression:
        ifCondition*: Node
        ifConsequence*: Node
        ifAlternative*: Node
      of NTCaseExpression:
        caseCondition*: Node
        casePatterns*: seq[CasePattern]
      of NTArrayLiteral: arrayElements*: seq[Node]
      of NTHashMapLiteral: hashMapElements*: OrderedTable[Node, Node]
      of NTIndexOperation:
        indexOpLeft*: Node
        indexOpIndex*: Node
      of NTModule:
        moduleName*: string
        moduleStatements*: seq[Node]
      of NTMacroLiteral:
        macroBody*: Node
        macroParams*: seq[Node]
        macroName*: Node
  CasePattern* = tuple[condition: Node, consequence: Node]

proc toCode*(node: Node): string =
  return case node.nodeType:
    of NTIntegerLiteral: $node.intValue
    of NTFLoatLiteral: $node.floatValue
    of NTBoolean: $node.boolValue
    of NTNil: "nil"
    of NTExpressionStatement:
      if node.expression != nil: node.expression.toCode() else: ""
    of NTPrefixExpression:
      if node.prefixOperator == "#":
        node.prefixOperator & " " & node.prefixRight.toCode()
      elif len(node.prefixOperator) == 1:
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
    of NTDestructAssignStatement:
      let keys: seq[string] = map(
        node.destructAssignNamesAndIndexes,
        proc(x: (Node, Node)): string = x[0].identValue
      )
      "let [" & join(keys, ", ") & "] = " & toCode(node.destructAssignValue)
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
      node.pipeLRLeft.toCode() & " |> " & node.pipeLRRight.toCode()
    of NTPipeRL:
      node.pipeRLLeft.toCode() & " <| " & node.pipeRLRight.toCode()
    of NTFNCompositionLR:
      node.fnCompositionLRLeft.toCode() & " >> " & node.fnCompositionLRRight.toCode()
    of NTFNCompositionRL:
      node.fnCompositionRLLeft.toCode() & " << " & node.fnCompositionRLRight.toCode()
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
    of NTIndexOperation:
      node.indexOpLeft.toCode() & "[" & node.indexOpIndex.toCode() & "]"
    of NTModule: "<module>"
    of NTMacroLiteral:
      let
        paramsCode: seq[string] = map(node.macroParams, proc (x: Node): string = toCode(x))
        paramsCodeString: string = join(paramsCode, ", ")
      if node.macroName != nil:
        "macro " & node.macroName.identValue & "(" & paramsCodeString & ") " & node.macroBody.toCode() & " end"
      else:
        "macro (" & paramsCodeString & ") " & node.macroBody.toCode() & " end"

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

proc newIntegerLiteral*(intValue: int): Node =
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

proc newDestructAssignStatement*(
  token: Token,
  destructAssignNamesAndIndexes: seq[(Node, Node)],
  destructAssignValue: Node
): Node =
  return Node(
    nodeType: NodeType.NTDestructAssignStatement,
    token: token,
    destructAssignNamesAndIndexes: destructAssignNamesAndIndexes,
    destructAssignValue: destructAssignValue
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

proc newMacroLiteral*(
  token: Token,
  macroBody: Node,
  macroParams: seq[Node],
  macroName: Node
): Node =
  return Node(
    nodeType: NodeType.NTMacroLiteral,
    token: token,
    macroBody: macroBody,
    macroParams: macroParams,
    macroName: macroName
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

proc newPipeLR*(token: Token, pipeLRLeft: Node, pipeLRRight: Node): Node =
  return Node(
    token: token,
    nodeType: NodeType.NTPipeLR,
    pipeLRLeft: pipeLRLeft,
    pipeLRRight: pipeLRRight
  )

proc newPipeRL*(token: Token, pipeRLLeft: Node, pipeRLRight: Node): Node =
  return Node(
    token: token,
    nodeType: NodeType.NTPipeRL,
    pipeRLLeft: pipeRLLeft,
    pipeRLRight: pipeRLRight
  )

proc newFNCompositionLR*(
  token: Token, fnCompositionLRLeft: Node, fnCompositionLRRight: Node
): Node =
  return Node(
    token: token,
    nodeType: NodeType.NTFNCompositionLR,
    fnCompositionLRLeft: fnCompositionLRLeft,
    fnCompositionLRRight: fnCompositionLRRight
  )

proc newFNCompositionRL*(
  token: Token, fnCompositionRLLeft: Node, fnCompositionRLRight: Node
): Node =
  return Node(
    token: token,
    nodeType: NodeType.NTFNCompositionRL,
    fnCompositionRLLeft: fnCompositionRLLeft,
    fnCompositionRLRight: fnCompositionRLRight
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

proc newIndexOperation*(
  token: Token,
  indexOpLeft: Node,
  indexOpIndex: Node
): Node =
  return Node(
    nodeType: NodeType.NTIndexOperation,
    token: token,
    indexOpLeft: indexOpLeft,
    indexOpIndex: indexOpIndex
  )

proc newModule*(moduleName: string, moduleStatements: seq[Node]): Node =
  return Node(
    nodeType: NodeType.NTModule,
    moduleName: moduleName,
    moduleStatements: moduleStatements
  )

proc newProgram*(statements: seq[Node]): Node =
  return Node(nodeType: NodeType.NTProgram, statements: statements)
