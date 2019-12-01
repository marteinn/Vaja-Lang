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
  OpNot,
  OpJump,
  OpJumpNotThruthy,
  OpNil,
  OpSetGlobal,
  OpGetGlobal,
  OpCombine,
  OpArray
from obj import Obj, newInteger, newStr
from ast import Node, NodeType
from symbol_table import newSymbolTable, SymbolTable, define, resolve, Symbol, `$`
import strformat

type
  Bytecode* = ref object
    instructions*: Instructions
    constants*: seq[Obj]
  CompilerError* = ref object
    message*: string
  EmittedInstruction* = ref object
    opCode: OpCode
    position: int
  Compiler* = ref object
    instructions*: Instructions
    constants*: seq[Obj]
    symbolTable*: SymbolTable
    lastInstruction: EmittedInstruction
    prevInstruction: EmittedInstruction

proc newCompiler*(): Compiler =
  return Compiler(instructions: @[], constants: @[], symbolTable: newSymbolTable())

proc newCompiler*(constants: var seq[Obj], symbolTable: var SymbolTable): Compiler =
  var compiler = newCompiler()
  compiler.constants = constants
  compiler.symbolTable = symbolTable
  return compiler

method setLastInstruction(compiler: var Compiler, op: OpCode, position: int) {.base.} =
  let
    prev = compiler.lastInstruction
    last = EmittedInstruction(opCode: op, position: position)

  compiler.prevInstruction = prev
  compiler.lastInstruction = last

method addInstruction(compiler: var Compiler, instructions: seq[byte]): int {.base.} =
  let posNewInstruction = len(compiler.instructions)
  compiler.instructions.add(instructions)
  return posNewInstruction

method emit*(compiler: var Compiler, op: OpCode, operands: seq[int]): int {.base.} =
  let
    instructions = make(op, operands)
    pos = compiler.addInstruction(instructions)

  compiler.setLastInstruction(op, pos)
  return pos

method emit*(compiler: var Compiler, op: OpCode): int {.base.} =
  return emit(compiler, op, @[])

method addConstant*(compiler: var Compiler, obj: Obj): int {.base.} =
  compiler.constants.add(obj)
  return len(compiler.constants) - 1

method replaceInstruction(compiler: var Compiler, pos: int, newInstruction: seq[byte]) {.base.} =
  for i, instruction in newInstruction:
    compiler.instructions[pos+i] = instruction

method changeOperand(compiler: var Compiler, opPos: int, operand: int) {.base.} =
  let op = OpCode(compiler.instructions[opPos])
  let newInstruction = make(op, @[operand])

  compiler.replaceInstruction(opPos, newInstruction)

method removeLastPop(compiler: var Compiler) {.base.} =
  discard pop(compiler.instructions)
  compiler.lastInstruction = compiler.prevInstruction

method compile*(compiler: var Compiler, node: Node): CompilerError {.base.} =
  case node.nodeType:
    of NodeType.NTProgram:
      for statement in node.statements:
        let err = compiler.compile(statement)
        if err != nil:
          return err
    of NodeType.NTBlockStatement:
      for statement in node.blockStatements:
        let err = compiler.compile(statement)
        if err != nil:
          return err
    of NodeType.NTExpressionStatement:
      let err = compiler.compile(node.expression)
      if err != nil:
        return err
      discard compiler.emit(OpPop)
    of NodeType.NTIfExpression:
      let err = compiler.compile(node.ifCondition)
      if err != nil:
        return err

      let jumpNotTruthyPos = compiler.emit(OpJumpNotThruthy, @[9999])
      let cErr = compiler.compile(node.ifConsequence)
      if cErr != nil:
        return cErr

      if compiler.lastInstruction.opCode == OpPop:
        compiler.removeLastPop()

      let jumpPos = compiler.emit(OpJump, @[9999])
      let afterConsPos = len(compiler.instructions)
      compiler.changeOperand(jumpNotTruthyPos, afterConsPos)

      if node.ifAlternative == nil:
        discard compiler.emit(OpNil)
      else:
        let altError = compiler.compile(node.ifAlternative)
        if altError != nil:
          return altError

        if compiler.lastInstruction.opCode == OpPop:
          compiler.removeLastPop()

      let afterAltPos = len(compiler.instructions)
      compiler.changeOperand(jumpPos, afterAltPos)
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
        of "++":
          discard compiler.emit(OpCombine)
        else:
          return CompilerError(message: fmt"Unkown infix operator {node.infixOperator}")
    of NodeType.NTIntegerLiteral:
      let obj = newInteger(node.intValue)
      discard compiler.emit(OpConstant, @[compiler.addConstant(obj)])
    of NodeType.NTStringLiteral:
      let obj = newStr(node.strValue)
      discard compiler.emit(OpConstant, @[compiler.addConstant(obj)])
    of NodeType.NTBoolean:
      if node.boolValue:
        discard compiler.emit(OpTrue)
      else:
        discard compiler.emit(OpFalse)
    of NodeType.NTArrayLiteral:
      for element in node.arrayElements:
        let err = compiler.compile(element)
        if err != nil:
          return err
      discard compiler.emit(OpArray, @[len(node.arrayElements)])

    of NodeType.NTAssignStatement:
      let err = compiler.compile(node.assignValue)
      if err != nil:
        return err
      let symbol: Symbol = compiler.symbolTable.define(node.assignName.identValue)
      discard compiler.emit(OpSetGlobal, @[symbol.index])
    of NodeType.NTIdentifier:
      let
        symbolRes: (Symbol, bool) = compiler.symbolTable.resolve(node.identValue)
        symbol: Symbol = symbolRes[0]

      if not symbolRes[1]:
        return CompilerError(message: "Name " & node.identValue & " is not defined")

      discard compiler.emit(OpGetGlobal, @[symbol.index])
    else:
      return nil
  return nil

method toBytecode*(compiler: Compiler): Bytecode {.base.} =
  return Bytecode(
    instructions: compiler.instructions,
    constants: compiler.constants
  )
