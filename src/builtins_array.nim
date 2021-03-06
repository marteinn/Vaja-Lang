import tables
import sequtils
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newBuiltinModule,
  newInteger,
  newArray,
  Env,
  newEnv,
  inspect,
  compareObj,
  OBJ_TRUE,
  OBJ_FALSE
import test_utils

proc arrayLen(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTArray)

  let obj: Obj = arguments[0]
  return newInteger(intValue=len(obj.arrayElements))

proc arrayHead(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTArray)

  let obj: Obj = arguments[0]
  return obj.arrayElements[0]

proc arrayLast(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTArray)

  let obj: Obj = arguments[0]
  return obj.arrayElements[high(obj.arrayElements)]

proc arrayMap(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, arrayMap)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 1, ObjType.OTArray)

  let
    fn: Obj = arguments[0]
    arr: Obj = arguments[1]
  let mapped: seq[Obj] = map(arr.arrayElements, proc (x: Obj): Obj =
    var env: Env = newEnv()
    return applyFn(fn, @[x], env)
  )
  return newArray(arrayElements=mapped)

proc arrayReduce(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 3, arrayReduce)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 2, ObjType.OTArray)

  let
    fn: Obj = arguments[0]
    initial: Obj = arguments[1]
    arr: Obj = arguments[2]
  result = initial
  for curr in arr.arrayElements:
    var env: Env = newEnv()
    result = applyFn(fn, @[result, curr], env)

proc arrayFilter(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, arrayFilter)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 1, ObjType.OTArray)

  let
    fn: Obj = arguments[0]
    arr: Obj = arguments[1]
  let filtered: seq[Obj] = filter(arr.arrayElements, proc (x: Obj): bool =
    var env: Env = newEnv()
    let res: Obj = applyFn(fn, @[x], env)
    if res.objType != OTBoolean:
      return res.boolValue
    return res.boolValue
  )
  return newArray(arrayElements=filtered)

proc arrayPush(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, arrayPush)
  requireArgOfType(arguments, 1, ObjType.OTArray)

  let
    el: Obj = arguments[0]
    arr: Obj = arguments[1]
    arrayElements: seq[Obj] = concat(arr.arrayElements, @[el])
  return newArray(arrayElements=arrayElements)

proc arrayDeleteAt(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, arrayDeleteAt)
  requireArgOfType(arguments, 0, ObjType.OTInteger)
  requireArgOfType(arguments, 1, ObjType.OTArray)

  let
    index: Obj = arguments[0]
    arr: Obj = arguments[1]
  var arrayElements: seq[Obj] = arr.arrayElements
  arrayElements.delete(index.intValue, index.intValue)
  return newArray(arrayElements=arrayElements)

proc arrayAppend(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, arrayAppend)
  requireArgOfType(arguments, 0, ObjType.OTArray)
  requireArgOfType(arguments, 1, ObjType.OTArray)

  let
    elements: Obj = arguments[0]
    arr: Obj = arguments[1]
    arrayElements = concat(elements.arrayElements, arr.arrayElements)
  return newArray(arrayElements=arrayElements)

proc arrayReplaceAt(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 3, arrayReplaceAt)
  requireArgOfType(arguments, 0, ObjType.OTInteger)
  requireArgOfType(arguments, 2, ObjType.OTArray)

  let
    index: Obj = arguments[0]
    obj: Obj = arguments[1]
    arr: Obj = arguments[2]
  var arrayElements: seq[Obj] = arr.arrayElements
  arrayElements[index.intValue] = obj
  return newArray(arrayElements=arrayElements)

proc arrayTail(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTArray)

  let
    arr: Obj = arguments[0]
    arrayElements = arr.arrayElements[1..high(arr.arrayElements)]
  return newArray(arrayElements=arrayElements)

proc arrayContains(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, arrayAppend)
  requireArgOfType(arguments, 1, ObjType.OTArray)

  let
    needle: Obj = arguments[0]
    arr: Obj = arguments[1]

  for x in arr.arrayElements:
    if compareObj(needle, x):
      return OBJ_TRUE

  return OBJ_FALSE

let functions*: OrderedTable[string, Obj] = {
  "len": newBuiltin(builtinFn=arrayLen),
  "head": newBuiltin(builtinFn=arrayHead),
  "last": newBuiltin(builtinFn=arrayLast),
  "map": newBuiltin(builtinFn=arrayMap),
  "filter": newBuiltin(builtinFn=arrayFilter),
  "reduce": newBuiltin(builtinFn=arrayReduce),
  "push": newBuiltin(builtinFn=arrayPush),
  "deleteAt": newBuiltin(builtinFn=arrayDeleteAt),
  "append": newBuiltin(builtinFn=arrayAppend),
  "replaceAt": newBuiltin(builtinFn=arrayReplaceAt),
  "tail": newBuiltin(builtinFn=arrayTail),
  "contains": newBuiltin(builtinFn=arrayContains),
}.toOrderedTable

let arrayModule*: Obj = newBuiltinModule(moduleFns=functions)
