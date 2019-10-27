from obj import Obj, ObjType, inspect

template requireNumArgs*(arguments: seq[Obj], numArgs: int) =
  if len(arguments) != numArgs:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want " & $numArgs
    )

template requireArgOfTypes*(arguments: seq[Obj], index: int, reqObjTypes: seq[ObjType]) =
  let arg: Obj = arguments[index]
  if not (arg.objType in reqObjTypes):
    let reqTypes: string = reqObjTypes.map(proc (x: ObjType): string =
      $x
    ).join(" or ")
    return newError(
      errorMsg="Argument " & $index & " was " & $(arg.objType) & ", want " & reqTypes
    )

template requireArgOfType*(arguments: seq[Obj], index: int, reqObjType: ObjType) =
  let arg: Obj = arguments[index]
  if arg.objType != reqObjType:
    return newError(
      errorMsg="Argument " & $index & " was " & $(arg.objType) & ", want " & $(reqObjType)
    )
