import sequtils
from ast import
  Node,
  NodeType,
  toCode
from obj import
  Obj,
  Env,
  ObjType,
  setVar,
  getVar,
  inspectEnv,
  containsVar,
  newMacro,
  newQuote,
  newEnclosedEnv,
  newError
from ast_modify import modify
from evaluator import eval

proc isMacroDefinition(node: Node): bool =
  if node.nodeType == NTMacroLiteral:
    return true

  if node.nodeType == NTExpressionStatement and
    node.expression.nodeType == NTMacroLiteral:
    return true

  if node.nodeType == NTAssignStatement and
    node.assignValue.nodeType == NTMacroLiteral:
    return true

  return false

proc addMacro(node: Node, env: var Env): void =
  var
    macroName: string
    macroNode: Node

  if node.nodeType == NTExpressionStatement:
    macroName = node.expression.macroName.identValue
    macroNode = node.expression

  if node.nodeType == NTAssignStatement:
    macroName = node.assignName.identValue
    macroNode = node.assignValue

  let macroObj: Obj = newMacro(
    macroBody=macroNode.macroBody,
    macroEnv=env,
    macroParams=macroNode.macroParams
  )
  discard setVar(env, macroName, macroObj)

proc defineMacros*(program: var Node, env: var Env): void =
  var definitions: seq[int] = @[]
  for index, statement in program.statements:
    if isMacroDefinition(statement):
      addMacro(statement, env)
      definitions.add(index)

  var statements: seq[Node] = program.statements
  for index in countdown(high(definitions), low(definitions)):
    let defIndex: int = definitions[index]
    statements.delete(defIndex, defIndex)

  program.statements = statements
  discard

proc isMacroCall(node: Node, env: var Env): (bool, Obj) =
  if node.nodeType != NodeType.NTIdentifier:
    return (false, nil)

  if not containsVar(env, node.identValue):
    return (false, nil)

  let obj = getVar(env, node.identValue)
  if obj.objType != ObjType.OTMacro:
    return (false, nil)

  return (true, obj)

proc quoteArgs(args: seq[Node]): seq[Obj] =
  return map(args, proc (x: Node): Obj = newQuote(x))

proc expandMacroEnv(macroObj: Obj, args: seq[Obj]): Env =
  var extendedEnv: Env = newEnclosedEnv(macroObj.macroEnv)

  for index, param in macroObj.macroParams:
    discard setVar(extendedEnv, param.identValue, args[index])

  return extendedEnv

proc evalMacroModifier(node: Node, env: var Env): Node =
  if node.nodeType != NodeType.NTCallExpression:
    return node

  let
    isMacroCallResp: (bool, Obj) = isMacroCall(node.callFunction, env)
    isMacro = isMacroCallResp[0]

  if not isMacro:
    return node

  let
    macroObj: Obj = isMacroCallResp[1]
    args: seq[Obj] = quoteArgs(node.callArguments)
  var evalEnv = expandMacroEnv(macroObj, args)

  let
    macroBody: Node = deepCopy(macroObj.macroBody)
    evaluated: Obj = eval(macroBody, evalEnv)
  if evaluated.objType != ObjType.OTQuote:
    echo "Error: Macro can only return OTQuote"
    quit(QuitFailure)

  return evaluated.quoteNode

proc expandMacros*(program: var Node, env: var Env): Node =
  return modify(program, evalMacroModifier, env)
