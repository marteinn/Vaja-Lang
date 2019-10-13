import math

from ast import Node, NodeType
from obj import
  Obj,
  Env,
  setVar,
  getVar,
  containsVar,
  newInteger,
  newFloat,
  newStr,
  newError,
  newFunction,
  newEnclosedEnv,
  newReturn,
  ObjType,
  hasNumberType,
  promoteToFloatValue,
  inspect,
  TRUE,
  FALSE


proc eval*(node: Node, env: var Env): Obj # Forward declaration

proc toBoolObj(boolValue: bool): Obj =
  if boolValue: TRUE else: FALSE

proc evalProgram(node: Node, env: var Env): Obj =
  var resultValue: Obj = nil
  for statement in node.statements:
    resultValue = eval(statement, env)

    if resultValue == nil:
      continue

    if resultValue.objType == ObjType.OTReturn:
      return resultValue

    if resultValue.objType == ObjType.OTError:
      return resultValue
  return resultValue

proc evalInfixIntegerExpression(operator: string, left: Obj, right: Obj): Obj =
  case operator:
    of "+":
      return newInteger(left.intValue + right.intValue)
    of "-":
      return newInteger(left.intValue - right.intValue)
    of "*":
      return newInteger(left.intValue * right.intValue)
    of "/":
      return newFloat(left.intValue / right.intValue)
    of "%":
      return newInteger(left.intValue mod right.intValue)
    of "**":
      return newInteger(left.intValue ^ right.intValue)
    of "==":
      return toBoolObj(left.intValue == right.intValue)
    of "!=":
      return toBoolObj(left.intValue != right.intValue)
    of ">":
      return toBoolObj(left.intValue > right.intValue)
    of ">=":
      return toBoolObj(left.intValue >= right.intValue)
    of "<":
      return toBoolObj(left.intValue < right.intValue)
    of "<=":
      return toBoolObj(left.intValue <= right.intValue)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalInfixFloatExpression(operator: string, left: Obj, right: Obj): Obj =
  var
    leftValue: float = left.promoteToFloatValue()
    rightValue: float = right.promoteToFloatValue()

  case operator:
    of "+":
      return newFloat(leftValue + rightValue)
    of "-":
      return newFloat(leftValue - rightValue)
    of "*":
      return newFloat(leftValue * rightValue)
    of "/":
      return newFloat(leftValue / rightValue)
    of "==":
      return toBoolObj(left.floatValue == right.floatValue)
    of "!=":
      return toBoolObj(left.floatValue != right.floatValue)
    of ">":
      return toBoolObj(left.floatValue > right.floatValue)
    of ">=":
      return toBoolObj(left.floatValue >= right.floatValue)
    of "<":
      return toBoolObj(left.floatValue < right.floatValue)
    of "<=":
      return toBoolObj(left.floatValue <= right.floatValue)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalInfixStringExpression(operator: string, left: Obj, right: Obj): Obj =
  case operator:
    of "&":
      return newStr(left.strValue & right.strValue)
    of "==":
      return toBoolObj(left.strValue == right.strValue)
    of "!=":
      return toBoolObj(left.strValue != right.strValue)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalInfixBooleanExpression(operator: string, left: Obj, right: Obj): Obj =
  case operator:
    of "and":
      return toBoolObj(left.boolValue and right.boolValue)
    of "or":
      return toBoolObj(left.boolValue or right.boolValue)
    of "==":
      return toBoolObj(left.boolValue == right.boolValue)
    of "!=":
      return toBoolObj(left.boolValue != right.boolValue)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalInfixExpression(operator: string, left: Obj, right: Obj): Obj =
  if left.objType == ObjType.OTInteger and right.objType == ObjType.OTInteger:
    return evalInfixIntegerExpression(operator, left, right)
  if left.hasNumberType() and right.hasNumberType():
    return evalInfixFloatExpression(operator, left, right)
  if left.objType == ObjType.OTString and right.objType == ObjType.OTString:
    return evalInfixStringExpression(operator, left, right)
  if left.objType == ObjType.OTBoolean and right.objType == ObjType.OTBoolean:
    return evalInfixBooleanExpression(operator, left, right)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalMinusOperatorExpression(right: Obj): Obj =
  if right.objType == ObjType.OTInteger:
    return newInteger(-right.intValue)
  if right.objType == ObjType.OTFloat:
    return newFloat(-right.floatValue)

  return newError(
    errorMsg="Prefix operator - does not support type " & $(right.objType)
  )

proc evalNotOperatorExpression(right: Obj): Obj =
  if right.objType == ObjType.OTBoolean:
    return toBoolObj(not right.boolValue)

  return newError(
    errorMsg="Prefix operator - does not support type " & $(right.objType)
  )

proc evalPrefixExpression(operator: string, right: Obj): Obj =
  case operator:
    of "-":
      return evalMinusOperatorExpression(right)
    of "not":
      return evalNotOperatorExpression(right)

  return newError(errorMsg="Unknown prefix operator " & operator)

proc evalBlockStatement(node: Node, env: var Env): Obj =
  var res: Obj = nil
  for statement in node.blockStatements:
    res = eval(statement, env)
    if res != nil and res.objType in [ObjType.OTReturn, ObjType.OTError]:
      return res
  return res

proc evalIdentifier(node: Node, env: var Env) : Obj =
  var exists: bool = containsVar(env, node.identValue)

  if not exists:
    return newError(errorMsg="Name " & node.identValue & " is not defined")

  return getVar(env, node.identValue)

proc evalExpressions(expressions: seq[Node], env: var Env): seq[Obj] =
  var res: seq[Obj] = @[]

  for exp in expressions:
    var evaluated: Obj = eval(exp, env)
    res.add(evaluated)

  return res

proc extendFunctionEnv(fn: Obj, arguments: seq[Obj]): Env =
  var enclosedEnv: Env = newEnclosedEnv(fn.functionEnv)
  for index, param in fn.functionParams:
    enclosedEnv = setVar(enclosedEnv, param.identValue, arguments[index])

  return enclosedEnv

proc unwrapReturnValue(obj: Obj): Obj =
  if obj.objType == ObjType.OTReturn:
    return obj.returnValue
  return obj

proc applyFunction(fn: Obj, arguments: seq[Obj], env: var Env): Obj =
  var extendedEnv: Env = extendFunctionEnv(fn, arguments)
  var res: Obj = eval(fn.functionBody, extendedEnv)

  # TODO: Add builtin call
  return unwrapReturnValue(res)

proc eval*(node: Node, env: var Env): Obj =
  case node.nodeType:
    of NTProgram: evalProgram(node, env)
    of NTExpressionStatement: eval(node.expression, env)
    of NTIntegerLiteral: newInteger(intValue=node.intValue)
    of NTFloatLiteral: newFloat(floatValue=node.floatValue)
    of NTStringLiteral: newStr(strValue=node.strValue)
    of NTInfixExpression:
      var infixLeft: Obj = eval(node.infixLeft, env)
      var infixRight: Obj = eval(node.infixRight, env)
      evalInfixExpression(
        node.infixOperator, infixLeft, infixRight
      )
    of NTPrefixExpression:
      var prefixRight: Obj = eval(node.prefixRight, env)
      evalPrefixExpression(node.prefixOperator, prefixRight)
    of NTAssignStatement:
      var assignmentValue = eval(node.assignValue, env)
      env = setVar(env, node.assignName.identValue, assignmentValue)
      nil
    of NTIdentifier: evalIdentifier(node, env)
    of NTBoolean: toBoolObj(node.boolValue)
    of NTBlockStatement: evalBlockStatement(node, env)
    of NTFunctionLiteral:
      var
        fn: Obj = newFunction(
          functionBody=node.functionBody,
          functionEnv=env,
          functionParams=node.functionParams
        )
      if node.functionName != nil:
        discard setVar(env, node.functionName.identValue, fn)
        nil
      else:
        fn
    of NTCallExpression:
      var fn: Obj = eval(node.callFunction, env)
      var arguments: seq[Obj] = evalExpressions(node.callArguments, env)
      applyFunction(fn, arguments, env)
    of NTReturnStatement:
      var returnValue: Obj = eval(node.returnValue, env)
      # TODO: Add error check
      newReturn(returnValue=returnValue)
