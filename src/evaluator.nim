from ast import Node, NodeType
from obj import Obj, Env, newInteger, ObjType


proc eval*(node: Node, env: Env): Obj # Forward declaration

proc evaluateProgram(node: Node, env: Env): Obj =
  var resultValue: Obj = nil
  for statement in node.statements:
    resultValue = eval(statement, env)
  return resultValue

proc evalInfixIntegerExpression(operator: string, left: Obj, right: Obj): Obj =
  case operator:
    of "+":
      return newInteger(left.intValue + right.intValue)
    of "-":
      return newInteger(left.intValue - right.intValue)
    of "*":
      return newInteger(left.intValue * right.intValue)
  nil

proc evalInfixExpression(operator: string, left: Obj, right: Obj): Obj =
  if left.objType == ObjType.OTInteger and right.objType == ObjType.OTInteger:
    return evalInfixIntegerExpression(operator, left, right)

  nil

proc eval*(node: Node, env: Env): Obj =
  case node.nodeType:
    of NTProgram: evaluateProgram(node, env)
    of NTExpressionStatement: eval(node.expression, env)
    of NTIntegerLiteral: newInteger(intValue=node.intValue)
    of NTInfixExpression:
      var infixLeft: Obj = eval(node.infixLeft, env)
      var infixRight: Obj = eval(node.infixRight, env)
      evalInfixExpression(
        node.infixOperator, infixLeft, infixRight
      )
    else: nil
