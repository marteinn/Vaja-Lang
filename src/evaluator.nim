import math

from ast import Node, NodeType, toCode
from obj import
  Obj,
  Env,
  setVar,
  getVar,
  inspectEnv,
  inspectEnv,
  containsVar,
  newInteger,
  newFloat,
  newStr,
  newError,
  newFunction,
  newFunctionGroup,
  newEnclosedEnv,
  newReturn,
  addFunctionToArityGroup,
  getFunctionsByArity,
  ObjType,
  hasNumberType,
  promoteToFloatValue,
  inspect,
  TRUE,
  FALSE,
  NIL,
  compareObj



proc eval*(node: Node, env: var Env): Obj # Forward declaration

proc isError(obj: Obj): bool =
  if obj == NIL:
    return false

  return obj.objType == ObjType.OTError

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
  var exists: bool = env.containsVar(node.identValue)

  if not exists:
    return newError(errorMsg="Name " & node.identValue & " is not defined")

  return env.getVar(node.identValue)

proc evalExpressions(expressions: seq[Node], env: var Env): seq[Obj] =
  var res: seq[Obj] = @[]

  for exp in expressions:
    var evaluated: Obj = eval(exp, env)
    res.add(evaluated)

  return res

proc extendEnv(env: var Env, functionParams: seq[Node], arguments: seq[Obj]): Env =
  for index, param in functionParams:
    env = setVar(env, param.identValue, arguments[index])

  return env

proc extendFunctionEnv(env: Env, functionParams: seq[Node], arguments: seq[Obj]): Env =
  var enclosedEnv: Env = newEnclosedEnv(env)
  for index, param in functionParams:
    if param.nodeType != NTIdentifier:
      continue
    enclosedEnv = setVar(enclosedEnv, param.identValue, arguments[index])

  return enclosedEnv

proc unwrapReturnValue(obj: Obj): Obj =
  if obj.objType == ObjType.OTReturn:
    return obj.returnValue
  return obj

proc applyFunction(fn: Obj, arguments: seq[Obj], env: var Env): Obj =
  var
    extendedEnv: Env = extendFunctionEnv(
      fn.functionEnv, fn.functionParams, arguments
    )
    res: Obj = eval(fn.functionBody, extendedEnv)

  # TODO: Add builtin call
  return unwrapReturnValue(res)

proc evalIfExpression(node: Node, env: var Env): Obj =
  var condition: Obj = eval(node.ifCondition, env)
  if condition == TRUE:
    return eval(node.ifConsequence, env)
  if node.ifAlternative != nil:
    return eval(node.ifAlternative, env)
  return NIL

proc curryFunction(fn: Obj, arguments: seq[Obj], env: var Env): Obj =
  var
    remainingParams: seq[Node] =
      fn.functionParams[len(arguments)..len(fn.functionParams)-1]
    functionParams = fn.functionParams[0..len(arguments)-1]
    enclosedEnv = extendEnv(fn.functionEnv, functionParams, arguments)

  return newFunction(
    functionBody=fn.functionBody,
    functionEnv=enclosedEnv,
    functionParams=remainingParams,
  )

# TODO: Optimize pattern matching signature comparison
proc getMatchingFunction*(
  fnGroup: var Obj, arguments: seq[Obj], env: var Env
): Obj =
  var
    arity: int = len(arguments)
    fnList: seq[Obj] = getFunctionsByArity(fnGroup, arity)

  for fn in fnList:
    var
      functionParams: seq[Node] = fn.functionParams
      match: bool = true

    for index, param in functionParams:
      if param.nodeType == NTIdentifier:
        continue

      var
        paramObj: Obj = eval(param, env)
        argument: Obj = arguments[index]

      if not compareObj(paramObj, argument):
        match = false
        break

    if match:
      return fn

  return newError(errorMsg="Function is undefined")

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

      # Store named function into a arity based function group
      if node.functionName != nil:
        var
          functionGroup: Obj = nil
          functionName: string = node.functionName.identValue

        functionGroup =
          if containsVar(env, functionName):
            getVar(env, functionName)
          else:
            newFunctionGroup()

        functionGroup = addFunctionToArityGroup(functionGroup, fn)
        discard setVar(env, node.functionName.identValue, functionGroup)
        nil
      else:
        fn
    of NTCallExpression:
      var
        fnBase: Obj = eval(node.callFunction, env)
        arguments: seq[Obj] = evalExpressions(node.callArguments, env)
        callerArity: int = len(arguments)
        fn: Obj = nil

      if fnBase.objType == OTFunctionGroup:
        fn = getMatchingFunction(fnBase, arguments, env)

        if isError(fn):
          return fn
      else:
        fn = fnBase

        if len(arguments) > len(fn.functionParams):
          return newError(
            errorMsg="Function with arity " & $len(fn.functionParams) &
              " called with " & $len(arguments) & " arguments"
          )

      applyFunction(fn, arguments, env)
      # Apply currying
      #if len(arguments) < len(fn.functionParams):
        #curryFunction(fn, arguments, env)
      #else:
        #applyFunction(fn, arguments, env)
    of NTReturnStatement:
      var returnValue: Obj = eval(node.returnValue, env)
      # TODO: Add error check
      newReturn(returnValue=returnValue)
    of NTPipeLR:
      node.pipeRight.callArguments.add(node.pipeLeft)
      eval(node.pipeRight, env)
    of NTIfExpression: evalIfExpression(node, env)
    of NTNil: NIL
