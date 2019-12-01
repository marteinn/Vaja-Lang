import strformat
import tables
from compiler import Bytecode
from obj import
  Obj,
  ObjType,
  inspect,
  newError,
  newInteger,
  newFloat,
  newBoolean,
  newNil,
  newStr,
  newArray,
  newHashMap,
  `$`
from code import
  Instructions,
  readUint16,
  OpCode,
  OpConstant,
  OpAdd,
  OpPop,
  OpSub,
  OpMul,
  OpDiv,
  OpTrue,
  OpFalse,
  OpEqual,
  OpNotEqual,
  OpGreaterThan,
  OpMinus,
  OpNot,
  OpJump,
  OpJumpNotThruthy,
  OpNil,
  OpSetGlobal,
  OpGetGlobal,
  OpCombine,
  OpArray,
  OpHashMap,
  OpIndex

var
  OBJ_TRUE*: Obj = newBoolean(boolValue=true)
  OBJ_FALSE*: Obj = newBoolean(boolValue=false)
  OBJ_NIL*: Obj = newNil()

const
  stackSize: int = 2048
  globalsSize*: int = 65536

type
  VM* = ref object
    constants: seq[Obj]
    instructions: Instructions
    stack: seq[Obj]
    stackPointer: int
    globals: seq[Obj]
  VMError* = ref object
    message*: string

proc newVM*(bytecode: Bytecode): VM =
  return VM(
    constants: bytecode.constants,
    instructions: bytecode.instructions,
    stack: newSeq[Obj](stackSize),
    globals: newSeq[Obj](globalsSize),
    stackPointer: 0
  )

proc newVM*(bytecode: Bytecode, globals: var seq[Obj]): VM =
  return VM(
    constants: bytecode.constants,
    instructions: bytecode.instructions,
    stack: newSeq[Obj](stackSize),
    globals: globals,
    stackPointer: 0
  )

proc push(vm: var VM, obj: Obj): VMError =
  if vm.stackPointer >= stackSize:
    return VMError(message: "Stack overflow")

  vm.stack[vm.stackPointer] = obj
  vm.stackPointer += 1
  discard

proc pop(vm: var VM): Obj =
  let obj = vm.stack[vm.stackPointer-1]
  vm.stackPointer -= 1
  return obj

proc toBoolObj(boolValue: bool): Obj =
  if boolValue: OBJ_TRUE else: OBJ_FALSE

method execIntComparison(vm: var VM, opCode: OpCode, left: Obj, right: Obj): VMError {.base.} =
  case opCode:
    of OpEqual:
      return vm.push(toBoolObj(left.intValue == right.intValue))
    of OpNotEqual:
      return vm.push(toBoolObj(left.intValue != right.intValue))
    of OpGreaterThan:
      return vm.push(toBoolObj(left.intValue > right.intValue))
    else:
      return VMError(message: fmt"Unknown operation {opCode}")

method execComparison(vm: var VM, opCode: OpCode): VMError {.base.} =
  let rightObj = vm.pop()
  let leftObj = vm.pop()

  if leftObj.objType == ObjType.OTInteger and rightObj.objType == ObjType.OTInteger:
    return vm.execIntComparison(opCode, leftObj, rightObj)

  case opCode:
    of OpEqual:
      return vm.push(toBoolObj(leftObj == rightObj))
    of OpNotEqual:
      return vm.push(toBoolObj(leftObj != rightObj))
    else:
      return VMError(message: fmt"Unknown operation {opCode}")

method execNotOperator(vm: var VM, opCode: OpCode): VMError {.base.} =
  let rightObj = vm.pop()
  if rightObj.objType == ObjType.OTBoolean:
    return vm.push(toBoolObj(not rightObj.boolValue))

  if rightObj.objType == ObjType.OTNil:
    return vm.push(OBJ_TRUE)

  return VMError(message: fmt"Type {rightObj.objType} does not support not")

method execMinusOperator(vm: var VM, opCode: OpCode): VMError {.base.} =
  let rightObj = vm.pop()
  if rightObj.objType == ObjType.OTInteger:
    return vm.push(newInteger(-rightObj.intValue))
  return VMError(message: fmt"Type {rightObj.objType} does not support minus")

method execBinaryStringOp(vm: var VM, opCode: OpCode): VMError {.base.} =
  let right = vm.pop()
  let left = vm.pop()

  case opCode:
    of OpCombine:
      return vm.push(newStr(left.strValue & right.strValue))
    else:
      return VMError(message: fmt"Unknown binary operation {opCode}")

method execBinaryIntOp(vm: var VM, opCode: OpCode): VMError {.base.} =
  let rightObj = vm.pop()
  let leftObj = vm.pop()
  let rightValue = rightObj.intValue
  let leftValue = leftObj.intValue

  case opCode:
    of OpAdd:
      return vm.push(newInteger(leftValue + rightValue))
    of OpSub:
      return vm.push(newInteger(leftValue - rightValue))
    of OpMul:
      return vm.push(newInteger(leftValue * rightValue))
    of OpDiv:
      return vm.push(newFloat(leftValue / rightValue))
    else:
      return VMError(message: fmt"Unknown binary operation {opCode}")

method execIndexExpression(vm: var VM, left: Obj, index: Obj): VMError {.base.} =
  if left.objType == ObjType.OTHashMap:
    try:
      return vm.push(left.hashMapElements[index.strValue])
    except:
      return VMError(message: fmt"Key {index.strValue} not found in {left}")

  if left.objType == ObjType.OTArray and index.objType == ObjType.OTInteger:
    try:
      return vm.push(left.arrayElements[index.intValue])
    except:
      return VMError(message: fmt"Key {index.intValue} not found in {left}")

  return VMError(message: "Index operation is not supported")

method runVM*(vm: var VM): VMError {.base.} =
  var ip = 0
  while ip < len(vm.instructions):
    let
      instruction = vm.instructions[ip]
      opCode = OpCode(instruction)
    case opCode:
      of OpConstant:
        let constIndex = readUint16(
          vm.instructions[ip+1 .. len(vm.instructions)-1]
        )
        ip += 2

        let vmError: VMError = vm.push(vm.constants[constIndex])
        if vmError != nil:
          return vmError
      of OpNot:
        let vmError = vm.execNotOperator(opCode)
        if vmError != nil:
          return vmError
      of OpMinus:
        let vmError = vm.execMinusOperator(opCode)
        if vmError != nil:
          return vmError
      of OpAdd, OpSub, OpMul, OpDiv:
        let vmError = vm.execBinaryIntOp(opCode)
        if vmError != nil:
          return vmError
      of OpCombine:
        let vmError = vm.execBinaryStringOp(opCode)
        if vmError != nil:
          return vmError
      of OpPop:
        discard vm.pop
      of OpTrue:
        let vmError = vm.push(OBJ_TRUE)
        if vmError != nil:
          return vmError
      of OpFalse:
        let vmError = vm.push(OBJ_FALSE)
        if vmError != nil:
          return vmError
      of OpEqual, OpNotEqual, OpGreaterThan:
        let vmError = vm.execComparison(opCode)
        if vmError != nil:
          return vmError
      of OpJumpNotThruthy:
        let pos = readUint16(
          vm.instructions[ip+1 .. len(vm.instructions)-1]
        )
        ip += 2

        let condition = vm.pop()
        if not condition.boolValue:
          ip = pos - 1
      of OpJump:
        let pos = readUint16(
          vm.instructions[ip+1 .. len(vm.instructions)-1]
        )
        ip = pos - 1
      of OpNil:
        let vmError = vm.push(OBJ_NIL)
        if vmError != nil:
          return vmError
      of OpSetGlobal:
        let globalIndex = readUint16(
          vm.instructions[ip+1 .. len(vm.instructions)-1]
        )
        ip += 2

        vm.globals[globalIndex] = vm.pop()
      of OpGetGlobal:
        let globalIndex = readUint16(
          vm.instructions[ip+1 .. len(vm.instructions)-1]
        )
        ip += 2

        let vmError: VMError = vm.push(vm.constants[globalIndex])
        if vmError != nil:
          return vmError
      of OpArray:
        let arrayLength = readUint16(
          vm.instructions[ip+1 .. len(vm.instructions)-1]
        )
        ip += 2

        let
          startIndex = vm.stackPointer - arrayLength
          endIndex = vm.stackPointer - 1
        var
          elements: seq[Obj] = @[]

        for index in startIndex .. endIndex:
          elements.add(vm.stack[index])

        vm.stackPointer = vm.stackPointer - arrayLength

        let vmError: VMError = vm.push(newArray(elements))
        if vmError != nil:
          return vmError
      of OpHashMap:
        let
          hashMapLength = readUint16(
            vm.instructions[ip+1 .. len(vm.instructions)-1]
          )
          hashMapPairs = int(hashMapLength/2)
        ip += 2

        let
          startIndex = vm.stackPointer - hashMapLength
        var
          elements: OrderedTable[string, Obj] = initOrderedTable[string, Obj]()

        for index in 0..hashMapPairs-1:
          let
            keyObj = vm.stack[startIndex+(index*2)]
            valObj = vm.stack[startIndex+(index*2)+1]
          elements[keyObj.strValue] = valObj

        vm.stackPointer = vm.stackPointer - hashMapLength

        let vmError: VMError = vm.push(newHashMap(elements))
        if vmError != nil:
          return vmError
      of OpIndex:
        let index = vm.pop()
        let left = vm.pop()
        let vmError = vm.execIndexExpression(left, index)
        if vmError != nil:
          return vmError
      else:
        discard

    ip += 1

method stackTop*(vm: VM): Obj {.base.} =
  if len(vm.stack) == 0:
    return nil

  return vm.stack[vm.stackPointer-1]

method lastPoppedStackElement*(vm: VM): Obj {.base.} =
  return vm.stack[vm.stackPointer]
