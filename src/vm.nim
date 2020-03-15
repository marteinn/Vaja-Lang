import strformat
import tables
from compiler import Bytecode
from frame import Frame, newFrame, getInstructions
from obj import
  Obj,
  ObjType,
  Env,
  inspect,
  newError,
  newInteger,
  newFloat,
  newBoolean,
  newNil,
  newStr,
  newArray,
  newHashMap,
  newCompiledFunction,
  newClosure,
  `$`
from code import
  Instructions,
  readUint16,
  readUint8,
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
  OpIndex,
  OpCall,
  OpReturn,
  OpReturnValue,
  OpSetLocal,
  OpGetLocal,
  OpGetBuiltin,
  OpClosure,
  OpGetFree
from builtins import globals, globalsByIndex

var
  OBJ_TRUE*: Obj = newBoolean(boolValue=true)
  OBJ_FALSE*: Obj = newBoolean(boolValue=false)
  OBJ_NIL*: Obj = newNil()

const
  stackSize: int = 2048
  globalsSize*: int = 65536
  frameSize*: int = 1024

type
  VM* = ref object
    constants: seq[Obj]
    stack: seq[Obj]
    stackPointer*: int
    globals*: seq[Obj]
    frames: seq[Frame]
    framesIndex: int
  VMError* = ref object
    message*: string

proc newVM*(bytecode: Bytecode): VM =
  let
    mainFn: Obj = newCompiledFunction(bytecode.instructions, 0, 0)
    mainClosure: Obj = newClosure(mainFn, @[])
    mainFrame: Frame = newFrame(mainClosure, 0)
  var
    frames = newSeq[Frame](stackSize)

  frames[0] = mainFrame

  return VM(
    constants: bytecode.constants,
    stack: newSeq[Obj](stackSize),
    globals: newSeq[Obj](globalsSize),
    stackPointer: 0,
    frames: frames,
    framesIndex: 1,
  )

proc newVM*(bytecode: Bytecode, globals: var seq[Obj]): VM =
  let vm = newVM(bytecode)
  vm.globals = globals
  return vm

proc push(vm: var VM, obj: Obj): VMError =
  if vm.stackPointer >= stackSize:
    return VMError(message: "Stack overflow")

  vm.stack[vm.stackPointer] = obj
  vm.stackPointer += 1
  discard

method pop(vm: var VM): Obj {.base.} =
  let obj = vm.stack[vm.stackPointer-1]
  vm.stackPointer -= 1
  return obj

method currentFrame(vm: var VM): Frame {.base.} =
  return vm.frames[vm.framesIndex-1]

method pushFrame(vm: var VM, frame: Frame): Frame {.base.} =
  vm.frames[vm.framesIndex] = frame
  vm.framesIndex = vm.framesIndex + 1
  return frame

method pushClosure(vm: var VM, constIndex: int, numFree: int): VMError =
  let compiledFn: Obj = vm.constants[constIndex]
  if compiledFn.objType != ObjType.OTCompiledFunction:
    return VMError(message: fmt"{compiledFn.objType} is not a function")

  var
    free: seq[Obj] = newSeq[Obj](numFree)

  for i in 0 .. numFree-1:
    free[i] = vm.stack[vm.stackPointer-numFree+i]

  vm.stackPointer = vm.stackPointer - numFree

  let closure = newClosure(compiledFn, free)
  discard vm.push(closure)

method popFrame(vm: var VM): Frame {.base.} =
  vm.framesIndex = vm.framesIndex - 1
  return vm.frames[vm.framesIndex]

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

  if left.objType == ObjType.OTBuiltinModule:
    try:
      return vm.push(left.moduleFns[index.strValue])
    except:
      return VMError(message: fmt"Key {index.strValue} not found in {left}")

  return VMError(message: fmt"Index operation is not supported on {left.objType}")

method callFunction(vm: var VM, fn: Obj, numArgs: int): VMError {.base.} =
  if numArgs != fn.compiledFunctionNumParams:
    return VMError(message: fmt"Incorrect number of arguments, expected {fn.compiledFunctionNumParams}, got {numArgs}")

  let frame: Frame = newFrame(fn, vm.stackPointer-numArgs)
  vm.stackPointer = frame.basePointer + fn.compiledFunctionNumLocals
  discard vm.pushFrame(frame)

proc applyFunctionNoOp*(fn: Obj, arguments: seq[Obj], env: var Env): Obj =
  nil

method callBuiltin(vm: var VM, fn: Obj, numArgs: int): VMError {.base.} =
  let arguments: seq[Obj] = vm.stack[vm.stackPointer-numArgs .. vm.stackPointer-1]
  let res: Obj = fn.builtinFn(arguments, applyFunctionNoOp)
  vm.stackPointer = vm.stackPointer - numArgs - 1

  if res != nil:
    return vm.push(res)
  else:
    return vm.push(OBJ_NIL)

method callClosure(vm: var VM, closure: Obj, numArgs: int): VMError {.base.} =
  if numArgs != closure.closureFn.compiledFunctionNumParams:
    return VMError(message: fmt"Incorrect number of arguments, expected {closure.closureFn.compiledFunctionNumParams}, got {numArgs}")

  let frame: Frame = newFrame(closure, vm.stackPointer-numArgs)

  vm.stackPointer = frame.basePointer + closure.closureFn.compiledFunctionNumLocals
  discard vm.pushFrame(frame)

method execCalls(vm: var VM, numArgs: int): VMError {.base.} =
  let fn: Obj = vm.stack[vm.stackPointer-numArgs-1]

  case fn.objType:
    of ObjType.OTCompiledFunction:
      return vm.callFunction(fn, numArgs)
    of ObjType.OTBuiltin:
      return vm.callBuiltin(fn, numArgs)
    of ObjType.OTClosure:
      return vm.callClosure(fn, numArgs)
    else:
      return VMError(message: fmt"Calling non function of type {fn.objType}")

method runVM*(vm: var VM): VMError {.base.} =
  var
    ip: int
    instructions: Instructions
    opCode: OPCode

  while vm.currentFrame().ip < len(vm.currentFrame().getInstructions())-1:
    vm.currentFrame().ip += 1

    ip = vm.currentFrame().ip
    instructions = vm.currentFrame.getInstructions()
    opCode = OpCode(instructions[ip])

    case opCode:
      of OpConstant:
        let constIndex = readUint16(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 2

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
        discard vm.pop()
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
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 2

        let condition = vm.pop()
        if not condition.boolValue:
          vm.currentFrame().ip = pos - 1
      of OpJump:
        let pos = readUint16(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip = pos - 1
      of OpNil:
        let vmError = vm.push(OBJ_NIL)
        if vmError != nil:
          return vmError
      of OpSetGlobal:
        let globalIndex = readUint16(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 2
        vm.globals[globalIndex] = vm.pop()
      of OpGetGlobal:
        let globalIndex = readUint16(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 2

        let vmError: VMError = vm.push(vm.globals[globalIndex])
        if vmError != nil:
          return vmError
      of OpSetLocal:
        let localIndex = readUint8(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 1
        let frame = vm.currentFrame()
        vm.stack[frame.basePointer+localIndex] = vm.pop()
      of OpGetLocal:
        let localIndex = readUint8(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 1

        let frame = vm.currentFrame()
        let vmError: VMError = vm.push(
          vm.stack[frame.basePointer+localIndex]
        )
        if vmError != nil:
          return vmError
      of OpArray:
        let arrayLength = readUint16(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 2

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
            instructions[ip+1 .. len(instructions)-1]
          )
          hashMapPairs = int(hashMapLength/2)
        vm.currentFrame().ip += 2

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
      of OpCall:
        vm.currentFrame().ip += 1

        let numArgs = readUint8(
          instructions[ip+1 .. len(instructions)-1]
        )

        let vmError = vm.execCalls(numArgs)
        if vmError != nil:
          return vmError
      of OpReturnValue:
        let returnValue = vm.pop

        let frame = vm.popFrame()
        vm.stackPointer = frame.basePointer - 1

        let vmError: VMError = vm.push(returnValue)
        if vmError != nil:
          return vmError
      of OpReturn:
        let frame = vm.popFrame()
        vm.stackPointer = frame.basePointer - 1

        let vmError: VMError = vm.push(OBJ_NIL)
        if vmError != nil:
          return vmError
      of OpGetBuiltin:
        let builtinIndex = readUint8(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 1

        let builtin: Obj = globalsByIndex[builtinIndex][1]
        let vmError: VMError = vm.push(builtin)
        if vmError != nil:
          return vmError
      of OpClosure:
        let closureIndex = readUint16(
          instructions[ip+1 .. len(instructions)-1]
        )
        let numFree = code.readUint8(instructions[ip+3 .. len(instructions)-1])
        vm.currentFrame().ip += 3

        let vmError: VMError = vm.pushClosure(closureIndex, numFree)
        if vmError != nil:
          return vmError
      of OpGetFree:
        let freeIndex = readUint8(
          instructions[ip+1 .. len(instructions)-1]
        )
        vm.currentFrame().ip += 1

        let
          currentClosure = vm.currentFrame().closure
        let vmError: VMError = vm.push(currentClosure.closureFree[freeIndex])
        if vmError != nil:
          return vmError
      else:
        discard

method stackTop*(vm: VM): Obj {.base.} =
  if len(vm.stack) == 0:
    return nil

  return vm.stack[vm.stackPointer-1]

method lastPoppedStackElement*(vm: VM): Obj {.base.} =
  return vm.stack[vm.stackPointer]
