import tables
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newHashMap,
  newError,
  newArray,
  newStr,
  inspect
import test_utils

proc unitTestSuite(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 1, ObjType.OTArray)

  let
    nameObj: Obj = arguments[0]
    testsObj: Obj = arguments[1]
    arrayElements: seq[Obj] = @[nameObj, testsObj]
  return newArray(arrayElements=arrayElements)

proc unitTestSetup(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfTypes(arguments, 0, @[ObjType.OTFunction, ObjType.OTFunctionGroup])

  let
    exp: Obj = arguments[0]
    arrayElements: seq[Obj] = @[newStr(strValue="setup"), exp]
  return newArray(arrayElements=arrayElements)

proc unitTestTest(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfTypes(arguments, 1, @[ObjType.OTFunction, ObjType.OTFunctionGroup])

  let
    nameObj: Obj = arguments[0]
    exp: Obj = arguments[1]
    arrayElements: seq[Obj] = @[newStr(strValue="test"), nameObj, exp]
  return newArray(arrayElements=arrayElements)

let functions*: OrderedTable[string, Obj] = {
  "suite": newBuiltin(builtinFn=unitTestSuite),
  "setup": newBuiltin(builtinFn=unitTestSetup),
  "test": newBuiltin(builtinFn=unitTestTest),
}.toOrderedTable

let unitTestModule*: Obj = newHashMap(hashMapElements=functions)
