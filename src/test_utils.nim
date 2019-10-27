from strutils import join
import strutils
from sequtils import map
from obj import Obj, ObjType, inspect, newError

template requireNumArgs*(arguments: seq[Obj], numArgs: int) =
  if len(arguments) != numArgs:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want " & $numArgs
    )

template requireArgOfTypes*(arguments: seq[Obj], index: int, reqObjTypes: seq[ObjType]) =
  let arg: Obj = arguments[index]
  if not (arg.objType in reqObjTypes):
    let reqTypes: seq[string] = map(reqObjTypes, proc (x: ObjType): string =
      $x
    )
    let reqTypesStr: string = join(reqTypes, " or ")
    return newError(
      errorMsg="Argument " & $index & " was " & $(arg.objType) & ", want " & reqTypesStr
    )

template requireArgOfType*(arguments: seq[Obj], index: int, reqObjType: ObjType) =
  let arg: Obj = arguments[index]
  if arg.objType != reqObjType:
    return newError(
      errorMsg="Argument " & $index & " was " & $(arg.objType) & ", want " & $(reqObjType)
    )
