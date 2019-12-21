import math
import tables
import sequtils
from strutils import startsWith

from ast import
  Node,
  NodeType,
  toCode,
  CasePattern,
  newIntegerLiteral,
  newBlockStatement,
  newIdentifier,
  newCallExpression,
  newBoolean,
  newStringLiteral,
  newFloatLiteral,
  newNil,
  newArrayLiteral,
  newHashMapLiteral
from ast_modify import modify
from token import newEmptyToken, newToken, TokenType
from obj import
  Obj,
  Env,
  newEnv,
  mergeEnvs,
  setVar,
  getVar,
  inspectEnv,
  inspectEnv,
  containsDirectVar,
  containsVar,
  newInteger,
  newFloat,
  newStr,
  newError,
  newFunction,
  newFunctionGroup,
  newEnclosedEnv,
  newReturn,
  newArray,
  newHashMap,
  newModule,
  newQuote,
  addFunctionToGroup,
  ObjType,
  hasNumberType,
  promoteToFloatValue,
  inspect,
  OBJ_TRUE,
  OBJ_FALSE,
  OBJ_NIL,
  compareObj
from builtins import globals

proc eval*(node: Node, env: var Env): Obj # Forward declaration

proc isError(obj: Obj): bool =
  if obj == OBJ_NIL:
    return false

  return obj.objType == ObjType.OTError

proc toBoolObj(boolValue: bool): Obj =
  if boolValue: OBJ_TRUE else: OBJ_FALSE

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

proc evalModule(node: Node, env: var Env): Obj =
  var
    resultValue: Obj = nil
    moduleEnv: Env = newEnv()
  for statement in node.moduleStatements:
    if statement == nil:
      continue

    resultValue = eval(statement, moduleEnv)

    if resultValue == nil:
      continue

    if resultValue.objType == ObjType.OTReturn:
      return resultValue

    if resultValue.objType == ObjType.OTError:
      return resultValue

  let module = newModule(moduleName=node.moduleName, moduleEnv=moduleEnv)
  discard env.setVar(node.moduleName, module)
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
    of "++":
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

proc evalInfixArrayExpression(operator: string, left: Obj, right: Obj): Obj =
  case operator:
    of "++":
      let arrayElements = concat(left.arrayElements, right.arrayElements)
      return newArray(arrayElements=arrayElements)

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
  if left.objType == ObjType.OTArray and right.objType == ObjType.OTArray:
    return evalInfixArrayExpression(operator, left, right)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalMinusOperatorExpression(right: Obj): Obj =
  if right.objType == ObjType.OTInteger:
    return newInteger(-right.intValue)
  if right.objType == ObjType.OTFloat:
    return newFloat(-right.floatValue)

  return newError(
    errorMsg="Prefix operator \"-\" does not support type " & $(right.objType)
  )

proc evalNotOperatorExpression(right: Obj): Obj =
  if right.objType == ObjType.OTBoolean:
    return toBoolObj(not right.boolValue)
  if right.objType == ObjType.OTNil:
    return OBJ_TRUE

  return newError(
    errorMsg="Prefix operator \"not\" does not support type " & $(right.objType)
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
  if node.identValue.startsWith("_"):
    return newError(errorMsg="Invalid use of " & node.identValue & ", it represents a value to be ignored")

  let exists: bool = env.containsVar(node.identValue)
  if exists:
    return env.getVar(node.identValue)

  if contains(globals, node.identValue):
    return globals[node.identValue]

  return newError(errorMsg="Name " & node.identValue & " is not defined")

proc evalExpressions(expressions: seq[Node], env: var Env): seq[Obj] =
  var res: seq[Obj] = @[]

  for exp in expressions:
    var evaluated: Obj = eval(exp, env)
    if isError(evaluated):
      return @[evaluated]

    res.add(evaluated)

  return res

proc extendEnv(env: var Env, functionParams: seq[Node], arguments: seq[Obj]): Env =
  for index, param in functionParams:
    if param.identValue.startsWith("_"):
      continue
    env = setVar(env, param.identValue, arguments[index])

  return env

proc extendFunctionEnv(env: Env, functionParams: seq[Node], arguments: seq[Obj]): Env =
  var enclosedEnv: Env = newEnclosedEnv(env)
  for index, param in functionParams:
    if param.nodeType != NTIdentifier:
      continue
    enclosedEnv = setVar(enclosedEnv, param.identValue, arguments[index])

  return enclosedEnv

proc unwrapReturnValue*(obj: Obj): Obj =
  if obj.objType == ObjType.OTReturn:
    return obj.returnValue
  return obj

# TODO: Optimize pattern matching signature comparison
proc getMatchingFunction*(
  fnGroup: Obj, arguments: seq[Obj], env: var Env
): Obj =
  var
    arity: int = len(arguments)
    fnList: seq[Obj] = fnGroup.arityGroup[arity]

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

proc resolveAndApplyFunction*(fn: Obj, arguments: seq[Obj], env: var Env): Obj # Forward declaration

proc applyFunction*(fn: Obj, arguments: seq[Obj], env: var Env): Obj =
  if fn.objType == OTFunction:
    var
      extendedEnv: Env = extendFunctionEnv(
        fn.functionEnv, fn.functionParams, arguments
      )
      res: Obj = eval(fn.functionBody, extendedEnv)

    return unwrapReturnValue(res)

  if fn.objType == OTBuiltin:
    return fn.builtinFn(arguments, resolveAndApplyFunction)

proc resolveAndApplyFunction*(fn: Obj, arguments: seq[Obj], env: var Env): Obj =
  var
    resolvedFn: Obj =
      if fn.objType == OTFunctionGroup:
        getMatchingFunction(fn, arguments, env)
      else:
        fn

  if isError(resolvedFn):
    return resolvedFn

  if fn.objType == ObjType.OTFunction and len(arguments) > len(fn.functionParams):
    return newError(
      errorMsg="Function with arity " & $len(fn.functionParams) &
        " called with " & $len(arguments) & " arguments"
    )

  applyFunction(resolvedFn, arguments, env)


proc evalIfExpression(node: Node, env: var Env): Obj =
  var condition: Obj = eval(node.ifCondition, env)
  if condition == OBJ_TRUE:
    return eval(node.ifConsequence, env)
  if node.ifAlternative != nil:
    return eval(node.ifAlternative, env)
  return OBJ_NIL

proc evalCaseExpression(node: Node, env: var Env): Obj =
  var condition: Obj = eval(node.caseCondition, env)
  for casePattern in node.casePatterns:
    if casePattern.condition.nodeType == NTIdentifier:
      return eval(casePattern.consequence, env)

    var patternCondition: Obj = eval(casePattern.condition, env)
    if compareObj(condition, patternCondition):
      return eval(casePattern.consequence, env)

  return newError(errorMsg="No clause matching")

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

proc evalIndexOp(left: Obj, index: Obj): Obj =
  if left.objType == ObjType.OTHashMap:
    try:
      return left.hashMapElements[index.strValue]
    except:
      return newError(errorMsg="Key " & index.strValue & " not found")

  if left.objType == ObjType.OTArray and index.objType == ObjType.OTInteger:
    try:
      return left.arrayElements[index.intValue]
    except:
      return newError(errorMsg="Key " & $index.intValue & " not found")

  if left.objType == ObjType.OTBuiltinModule:
    try:
      return left.moduleFns[index.strValue]
    except:
      return newError(errorMsg="Key " & index.strValue & " not found")

  if left.objType == ObjType.OTModule:
    return getVar(left.moduleEnv, index.strValue)

  return newError(errorMsg="Index operation is not supported")

proc isUnquoteCall(node: Node): bool =
  if node.nodeType != NTCallExpression:
    return false

  return (
    node.callFunction.nodeType == NodeType.NTIdentifier and
    node.callFunction.identValue == "unquote"
  )

proc convertObjToNode(obj: Obj): Node =
  if obj == nil:
    return nil

  case obj.objType:
    of OTInteger:
      return newIntegerLiteral(
        token=newToken(
          tokenType=TokenType.INT,
          literal= $obj.intValue
        ),
        intValue=obj.intValue
      )
    of OTBoolean:
      return newBoolean(
        token=newToken(
          tokenType=if obj == OBJ_TRUE: TokenType.TRUE else: TokenType.FALSE,
          literal=if obj == OBJ_TRUE: "true" else: "false",
        ),
        boolValue=obj.boolValue
      )
    of OTString:
      return newStringLiteral(
        token=newToken(
          tokenType=TokenType.STRING,
          literal= obj.strValue
        ),
        strValue=obj.strValue
      )
    of OTFloat:
      return newFloatLiteral(
        token=newToken(
          tokenType=TokenType.FLOAT,
          literal= $obj.floatValue,
        ),
        floatValue=obj.floatValue
      )
    of OTNil:
      return newNil(
        token=newToken(
          tokenType=TokenType.NIL,
          literal= "nil"
        )
      )
    of OTArray:
      let nodeElements: seq[Node] = map(obj.arrayElements, convertObjToNode)
      return newArrayLiteral(
        token=newToken(
          tokenType=TokenType.LBRACKET,
          literal= "["
        ),
        arrayElements=nodeElements
      )
    of OTHashMap:
      var hashMapElements: OrderedTable[Node, Node] = initOrderedTable[Node, Node]()
      for key, value in obj.hashMapElements:
        let keyNode: Node = newStringLiteral(
          token=newToken(
            tokenType=TokenType.STRING,
            literal=key
          ),
          strValue=key
        )
        hashMapElements[keyNode] = convertObjToNode(value)

      return newHashMapLiteral(
        token=newToken(
          TokenType.LBRACE,
          literal="{"
        ),
        hashMapElements=hashMapElements
      )

    of OTQuote:
      return obj.quoteNode
    # TODO: Add obj to ast translations (ex regex)
    else:
      echo "Type " & $obj.objType & " is not supported by convertObjToNode"
      return nil

proc evalUnquoteModifier(node: Node, env: var Env): Node =
  if not isUnquoteCall(node):
    return node

  if len(node.callArguments) != 1:
    return node

  let obj = eval(node.callArguments[0], env)
  return convertObjToNode(obj)

proc evalUnquoteCalls(quoted: Node, env: var Env): Node =
  return modify(quoted, evalUnquoteModifier, env)

proc quote(node: Node, env: var Env): Obj =
  return newQuote(evalUnquoteCalls(node, env))

proc eval*(node: Node, env: var Env): Obj =
  case node.nodeType:
    of NTProgram: evalProgram(node, env)
    of NTModule: evalModule(node, env)
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
      let key = node.assignName.identValue
      if key.startsWith("_"):
        return nil

      var assignmentValue = eval(node.assignValue, env)

      if containsDirectVar(env, key):
        return newError(errorMsg="Variable " & key & " cannot be reassigned")

      env = setVar(env, key, assignmentValue)
      nil
    of NTDestructAssignStatement:
      var assignmentValue = eval(node.destructAssignValue, env)
      for item in node.destructAssignNamesAndIndexes:
        let
          key = item[0].identValue

        if key.startsWith("_"):
          continue

        let
          index = eval(item[1], env)
          indexValue = evalIndexOp(assignmentValue, index)
        if containsDirectVar(env, key):
          return newError(errorMsg="Variable " & key & " cannot be reassigned")

        env = setVar(env, key, indexValue)
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
          functionName: string = node.functionName.identValue
          functionGroup =
            if containsVar(env, functionName):
              env.getVar(functionName)
            else:
              newFunctionGroup()

        functionGroup = functionGroup.addFunctionToGroup(fn)
        discard env.setVar(node.functionName.identValue, functionGroup)
        nil
      else:
        fn
    of NTFNCompositionLR:
      let
        left = node.fnCompositionLRLeft
        right = node.fnCompositionLRRight
        token = newEmptyToken()

      let functionBody: Node = newBlockStatement(
          token=token,
          blockStatements= @[
            newCallExpression(
              token=token,
              callFunction=right,
              callArguments= @[
                newCallExpression(
                  token=token,
                  callFunction=left,
                  callArguments= @[
                    newIdentifier(token=token, identValue="x")
                  ]
                )
              ]
            )
          ]
        )

      newFunction(
        functionBody=functionBody,
        functionEnv=env,
        functionParams= @[
          newIdentifier(token=token, identValue="x")
        ]
      )
    of NTFNCompositionRL:
      let
        left = node.fnCompositionRLLeft
        right = node.fnCompositionRLRight
        token = newEmptyToken()

      let functionBody: Node = newBlockStatement(
          token=token,
          blockStatements= @[
            newCallExpression(
              token=token,
              callFunction=left,
              callArguments= @[
                newCallExpression(
                  token=token,
                  callFunction=right,
                  callArguments= @[
                    newIdentifier(token=token, identValue="x")
                  ]
                )
              ]
            )
          ]
        )

      newFunction(
        functionBody=functionBody,
        functionEnv=env,
        functionParams= @[
          newIdentifier(token=token, identValue="x")
        ]
      )
    of NTCallExpression:
      if node.callFunction.nodeType == NodeType.NTIdentifier and
        node.callFunction.identValue == "quote":
        return quote(node.callArguments[0], env)

      var
        fnBase: Obj = eval(node.callFunction, env)
        arguments: seq[Obj] = evalExpressions(node.callArguments, env)

      if len(arguments) > 0 and isError(arguments[0]):
        return arguments[0]

      resolveAndApplyFunction(fnBase, arguments, env)

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
      var pipeLRRight: Node
      deepCopy(pipeLRRight, node.pipeLRRight)
      pipeLRRight.callArguments.add(node.pipeLRLeft)
      eval(pipeLRRight, env)
    of NTPipeRL:
      var pipeRLLeft: Node
      deepCopy(pipeRLLeft, node.pipeRLLeft)
      pipeRLLeft.callArguments.add(node.pipeRLRight)
      eval(pipeRLLeft, env)
    of NTIfExpression: evalIfExpression(node, env)
    of NTCaseExpression: evalCaseExpression(node, env)
    of NTNil: OBJ_NIL
    of NTArrayLiteral:
      let elements: seq[Obj] = evalExpressions(node.arrayElements, env)
      if len(elements) > 0 and isError(elements[0]):
        return elements[0]
      newArray(arrayElements=elements)
    of NTHashMapLiteral:
      var elements: OrderedTable[string, Obj] = initOrderedTable[string, Obj]()
      for key, value in node.hashMapElements:
        let
          keyObj: Obj = eval(key, env)
          valObj: Obj = eval(value, env)

        if isError(valObj):
          return valObj

        if keyObj.objType != ObjType.OTString:
          return newError(
            errorMsg="Only string indexes are allowed, found " & $(keyObj.objType)
          )

        elements[keyObj.strValue] = valObj
      newHashMap(hashMapElements=elements)
    of NTIndexOperation:
      var
        left: Obj = eval(node.indexOpLeft, env)
        index: Obj = eval(node.indexOpIndex, env)
      evalIndexOp(left, index)
    of NTMacroLiteral:
      nil
