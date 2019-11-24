from code import
  Instructions,
  OpCode,
  make,
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
  OpNot
from obj import Obj, newInteger
from ast import Node, NodeType
import strformat

type
  Compiler* = ref object
    instructions*: Instructions
    constants*: seq[Obj]
  Bytecode* = ref object
    instructions*: Instructions
    constants*: seq[Obj]
  CompilerError* = ref object
    message*: string

proc newCompiler*(): Compiler =
  return Compiler(instructions: @[], constants: @[])

method addInstruction(compiler: var Compiler, instructions: seq[byte]): int {.base.} =
  let posNewInstruction = len(compiler.instructions)
  compiler.instructions.add(instructions)
  return posNewInstruction

method emit*(compiler: var Compiler, op: OpCode, operands: seq[int]): int {.base.} =
  let instructions = make(op, operands)
  return compiler.addInstruction(instructions)

method emit*(compiler: var Compiler, op: OpCode): int {.base.} =
  let instructions = make(op, @[])
  return compiler.addInstruction(instructions)

method addConstant*(compiler: var Compiler, obj: Obj): int {.base.} =
  compiler.constants.add(obj)
  return len(compiler.constants) - 1

method compile*(compiler: var Compiler, node: Node): CompilerError {.base.} =
  case node.nodeType:
    of NodeType.NTProgram:
      for statement in node.statements:
        let err = compiler.compile(statement)
        if err != nil:
          return err
    of NodeType.NTExpressionStatement:
      let err = compiler.compile(node.expression)
      if err != nil:
        return err
      discard compiler.emit(OpPop)
    of NodeType.NTPrefixExpression:
      let errRight = compiler.compile(node.prefixRight)
      if errRight != nil:
        return errRight
      case node.prefixOperator:
        of "-":
          discard compiler.emit(OpMinus)
        of "not":
          discard compiler.emit(OpNot)
        else:
          return CompilerError(
            message: fmt"Unkown infix operator {node.infixOperator}"
          )
    of NodeType.NTInfixExpression:
      if node.infixOperator == "<":
        let errRight = compiler.compile(node.infixRight)
        if errRight != nil:
          return errRight
        let errLeft = compiler.compile(node.infixLeft)
        if errLeft != nil:
          return errLeft
        discard compiler.emit(OpGreaterThan)
        return nil

      let errLeft = compiler.compile(node.infixLeft)
      if errLeft != nil:
        return errLeft
      let errRight = compiler.compile(node.infixRight)
      if errRight != nil:
        return errRight

      case node.infixOperator:
        of "+":
          discard compiler.emit(OpAdd)
        of "-":
          discard compiler.emit(OpSub)
        of "*":
          discard compiler.emit(OpMul)
        of "/":
          discard compiler.emit(OpDiv)
        of "==":
          discard compiler.emit(OpEqual)
        of "!=":
          discard compiler.emit(OpNotEqual)
        of ">":
          discard compiler.emit(OpGreaterThan)
        else:
          return CompilerError(message: fmt"Unkown infix operator {node.infixOperator}")
    of NodeType.NTIntegerLiteral:
      let obj = newInteger(node.intValue)
      discard compiler.emit(OpConstant, @[compiler.addConstant(obj)])
    of NodeType.NTBoolean:
      if node.boolValue:
        discard compiler.emit(OpTrue)
      else:
        discard compiler.emit(OpFalse)
    else:
      return nil
  return nil

method toBytecode*(compiler: Compiler): Bytecode {.base.} =
  return Bytecode(
    instructions: compiler.instructions,
    constants: compiler.constants
  )
