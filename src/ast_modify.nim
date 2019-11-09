import tables
from ast import Node, NodeType, hash
from obj import Env

proc modify*(
  node: Node,
  modifier: proc (node: Node, envEnv: var Env): Node {.closure.},
  env: var Env
): Node =
  case node.nodeType:
    of NTProgram:
      for index, statement in node.statements:
        node.statements[index] = modify(statement, modifier, env)
    of NTExpressionStatement:
      node.expression = modify(node.expression, modifier, env)
    of NTInfixExpression:
      node.infixLeft = modify(node.infixLeft, modifier, env)
      node.infixRight = modify(node.infixRight, modifier, env)
    of NTPrefixExpression:
      node.prefixRight = modify(node.prefixRight, modifier, env)
    of NTIndexOperation:
      node.indexOpLeft = modify(node.indexOpLeft, modifier, env)
      node.indexOpIndex = modify(node.indexOpIndex, modifier, env)
    of NTIfExpression:
      node.ifCondition = modify(node.ifCondition, modifier, env)
      node.ifConsequence = modify(node.ifConsequence, modifier, env)
      if node.ifAlternative != nil:
        node.ifAlternative = modify(node.ifAlternative, modifier, env)
    of NTBlockStatement:
      for index, statement in node.blockStatements:
        node.blockStatements[index] = modify(statement, modifier, env)
    of NTReturnStatement:
      node.returnValue = modify(node.returnValue, modifier, env)
    of NTAssignStatement:
      node.assignName = modify(node.assignName, modifier, env)
      node.assignValue = modify(node.assignValue, modifier, env)
    of NTDestructAssignStatement:
      for index, value in node.destructAssignNamesAndIndexes:
        node.destructAssignNamesAndIndexes[index] = (
          modify(value[0], modifier, env),
          modify(value[1], modifier, env)
        )
      node.destructAssignValue = modify(node.destructAssignValue, modifier, env)
    of NTFunctionLiteral:
      node.functionBody = modify(node.functionBody, modifier, env)
      for index, param in node.functionParams:
        node.functionParams[index] = modify(param, modifier, env)
    of NTArrayLiteral:
      for index, element in node.arrayElements:
        node.arrayElements[index] = modify(element, modifier, env)
    of NTHashMapLiteral:
      var newHashMapElements: OrderedTable[Node, Node] = initOrderedTable[Node, Node]()
      for key, val in node.hashMapElements:
        let newKey = modify(key, modifier, env)
        let newValue = modify(val, modifier, env)
        newHashMapElements[newKey] = newValue
      node.hashMapElements = newHashMapElements
    of NTPipeLR:
      node.pipeLRLeft = modify(node.pipeLRLeft, modifier, env)
      node.pipeLRRight = modify(node.pipeLRRight, modifier, env)
    of NTPipeRL:
      node.pipeRLLeft = modify(node.pipeRLLeft, modifier, env)
      node.pipeRLRight = modify(node.pipeRLRight, modifier, env)
    of NTFNCompositionLR:
      node.fnCompositionLRLeft = modify(node.fnCompositionLRLeft, modifier, env)
      node.fnCompositionLRRight = modify(node.fnCompositionLRRight, modifier, env)
    of NTFNCompositionRL:
      node.fnCompositionRLLeft = modify(node.fnCompositionRLLeft, modifier, env)
      node.fnCompositionRLRight = modify(node.fnCompositionRLRight, modifier, env)
    of NTCaseExpression:
      node.caseCondition = modify(node.caseCondition, modifier, env)
      for index, pair in node.casePatterns:
        node.casePatterns[index] = (
          modify(pair[0], modifier, env),
          modify(pair[1], modifier, env)
        )
    of NTModule:
      for index, statement in node.moduleStatements:
        node.moduleStatements[index] = modify(statement, modifier, env)
    else:
      discard

  return modifier(node, env)
