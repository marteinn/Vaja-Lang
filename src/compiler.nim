import strformat
import tables
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
  OpSetLocal,
  OpGetLocal,
  OpCombine,
  OpArray,
  OpHashMap,
  OpIndex,
  OpReturn,
  OpReturnValue,
  OpCall,
  OpGetBuiltin,
  OpClosure,
  OpGetFree
from obj import Obj, newInteger, newStr, newCompiledFunction
from ast import Node, NodeType
from symbol_table import
  newSymbolTable,
  newEnclosedSymbolTable,
  SymbolTable,
  define,
  defineBuiltin,
  resolve,
  Symbol,
  GLOBAL_SCOPE,
  LOCAL_SCOPE,
  BUILTIN_SCOPE,
  FREE_SCOPE,
  `$`
from builtins import globals

type
  Bytecode* = ref object
    instructions*: Instructions
    constants*: seq[Obj]
  CompilerError* = ref object
    message*: string
  EmittedInstruction* = ref object
    opCode*: OpCode
    position: int
  CompilationScope* = ref object
    instructions*: Instructions
    lastInstruction*: EmittedInstruction
    prevInstruction*: EmittedInstruction
  Compiler* = ref object
    constants*: seq[Obj]
    symbolTable*: SymbolTable
    scopes*: seq[CompilationScope]
    scopeIndex*: int

proc newCompilationScope(): CompilationScope =
  return CompilationScope(instructions: @[])

proc newCompiler*(): Compiler =
  let
    mainScope = newCompilationScope()
  var
    symbolTable = newSymbolTable()

  # TODO: Add better iteration
  var index: int = 0
  for key in globals.keys:
    discard symbolTable.defineBuiltin(index, key)
    index += 1

  return Compiler(
    constants: @[],
    symbolTable: symbolTable,
    scopes: @[mainScope],
  )

proc newCompiler*(constants: var seq[Obj], symbolTable: var SymbolTable): Compiler =
  var
    compiler = newCompiler()
  compiler.constants = constants
  compiler.symbolTable = symbolTable
  return compiler

method currentInstructions(compiler: var Compiler): Instructions {.base.} =
  return compiler.scopes[compiler.scopeIndex].instructions

method setLastInstruction(compiler: var Compiler, op: OpCode, position: int) {.base.} =
  var currentScope = compiler.scopes[compiler.scopeIndex]
  let
    prev = currentScope.lastInstruction
    last = EmittedInstruction(opCode: op, position: position)

  currentScope.prevInstruction = prev
  currentScope.lastInstruction = last

method addInstruction(compiler: var Compiler, instructions: seq[byte]): int {.base.} =
  let posNewInstruction = len(compiler.currentInstructions())
  var compilerInstructions = compiler.currentInstructions()

  compilerInstructions.add(instructions)
  compiler.scopes[compiler.scopeIndex].instructions = compilerInstructions
  return posNewInstruction

method lastInstructionIs(compiler: var Compiler, opCode: OPCode): bool {.base.} =
  if len(compiler.currentInstructions()) == 0:
    return false

  return compiler.scopes[compiler.scopeIndex].lastInstruction.opCode == opCode

method emit*(compiler: var Compiler, op: OpCode, operands: seq[int]): int {.base.} =
  let
    instructions = make(op, operands)
    pos = compiler.addInstruction(instructions)

  compiler.setLastInstruction(op, pos)
  return pos

method emit*(compiler: var Compiler, op: OpCode): int {.base.} =
  return emit(compiler, op, @[])

method enterScope*(compiler: var Compiler): int {.base.} =
  let
    scope = CompilationScope(instructions: @[])
  compiler.scopeIndex = compiler.scopeIndex + 1
  compiler.scopes.add(scope)
  compiler.symbolTable = newEnclosedSymbolTable(compiler.symbolTable)
  return compiler.scopeIndex

method leaveScope*(compiler: var Compiler): Instructions {.base.} =
  let instructions = compiler.currentInstructions()
  var scopes = compiler.scopes
  discard pop(scopes)

  compiler.scopes = scopes
  compiler.scopeIndex = compiler.scopeIndex - 1
  compiler.symbolTable = compiler.symbolTable.outer

  return instructions

method addConstant*(compiler: var Compiler, obj: Obj): int {.base.} =
  compiler.constants.add(obj)
  return len(compiler.constants) - 1

method replaceInstruction(compiler: var Compiler, pos: int, newInstruction: seq[byte]) {.base.} =
  var instructions = compiler.currentInstructions()
  for i, instruction in newInstruction:
    instructions[pos+i] = instruction

  compiler.scopes[compiler.scopeIndex].instructions = instructions

method changeOperand(compiler: var Compiler, opPos: int, operand: int) {.base.} =
  let op = OpCode(compiler.currentInstructions()[opPos])
  let newInstruction = make(op, @[operand])

  compiler.replaceInstruction(opPos, newInstruction)

method removeLastPop(compiler: var Compiler) {.base.} =
  var currentScope = compiler.scopes[compiler.scopeIndex]
  discard pop(compiler.scopes[compiler.scopeIndex].instructions)
  currentScope.lastInstruction = currentScope.prevInstruction

method loadSymbol(compiler: var Compiler, symbol: Symbol) {.base.} =
  case symbol.scope:
    of GLOBAL_SCOPE:
      discard compiler.emit(OpGetGlobal, @[symbol.index])
    of LOCAL_SCOPE:
      discard compiler.emit(OpGetLocal, @[symbol.index])
    of BUILTIN_SCOPE:
      discard compiler.emit(OpGetBuiltin, @[symbol.index])
    of FREE_SCOPE:
      discard compiler.emit(OpGetFree, @[symbol.index])

method replaceLastPopWithReturnValue(compiler: var Compiler) {.base.} =
  let currentScope = compiler.scopes[compiler.scopeIndex]
  compiler.replaceInstruction(
    currentScope.lastInstruction.position,
    make(OpReturnValue)
  )
  currentScope.lastInstruction.opCode = OpReturnValue

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
    of NodeType.NTFunctionLiteral:
      discard compiler.enterScope()

      for arg in node.functionParams:
        discard compiler.symbolTable.define(arg.identValue)

      let err = compiler.compile(node.functionBody)
      if err != nil:
        return err

      if compiler.lastInstructionIs(OpPop):
        compiler.replaceLastPopWithReturnValue()

      if not compiler.lastInstructionIs(OpReturnValue):
        discard compiler.emit(OpReturn)

      let
        freeSymbols = compiler.symbolTable.freeSymbols
        numLocals = compiler.symbolTable.numDefinitions
        instructions = compiler.leaveScope()

      for symbol in freeSymbols:
        compiler.loadSymbol(symbol)

      let
        compiledFn: Obj = newCompiledFunction(
          instructions=instructions,
          numLocals=numLocals,
          numParams=len(node.functionParams),
        )

      discard compiler.emit(
        OpClosure, @[compiler.addConstant(compiledFn), len(freeSymbols)]
      )
    of NodeType.NTCallExpression:
      let err = compiler.compile(node.callFunction)
      if err != nil:
        return err

      for arg in node.callArguments:
        var argErr = compiler.compile(arg)
        if argErr != nil:
          return argErr

      discard compiler.emit(OpCall, @[len(node.callArguments)])
    of NodeType.NTIfExpression:
      let err = compiler.compile(node.ifCondition)
      if err != nil:
        return err

      let jumpNotTruthyPos = compiler.emit(OpJumpNotThruthy, @[9999])
      let cErr = compiler.compile(node.ifConsequence)
      if cErr != nil:
        return cErr

      if compiler.lastInstructionIs(OpPop):
        compiler.removeLastPop()

      let jumpPos = compiler.emit(OpJump, @[9999])
      let afterConsPos = len(compiler.currentInstructions())
      compiler.changeOperand(jumpNotTruthyPos, afterConsPos)

      if node.ifAlternative == nil:
        discard compiler.emit(OpNil)
      else:
        let altError = compiler.compile(node.ifAlternative)
        if altError != nil:
          return altError

        if compiler.lastInstructionIs(OpPop):
          compiler.removeLastPop()

      let afterAltPos = len(compiler.currentInstructions())
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
    of NodeType.NTHashMapLiteral:
      for keyNode, valNode in node.hashMapElements:
        let keyErr = compiler.compile(keyNode)
        if keyErr != nil:
          return keyErr
        let valErr = compiler.compile(valNode)
        if valErr != nil:
          return valErr
      discard compiler.emit(OpHashMap, @[len(node.hashMapElements)*2])
    of NodeType.NTAssignStatement:
      let err = compiler.compile(node.assignValue)
      if err != nil:
        return err
      let symbol: Symbol = compiler.symbolTable.define(node.assignName.identValue)
      if symbol.scope == GLOBAL_SCOPE:
        discard compiler.emit(OpSetGlobal, @[symbol.index])
      else:
        discard compiler.emit(OpSetLocal, @[symbol.index])
    of NodeType.NTIdentifier:
      let
        symbolRes: (Symbol, bool) = compiler.symbolTable.resolve(node.identValue)
        symbol: Symbol = symbolRes[0]

      if not symbolRes[1]:
        return CompilerError(message: "Name " & node.identValue & " is not defined")

      compiler.loadSymbol(symbol)
    of NodeType.NTIndexOperation:
      let leftErr = compiler.compile(node.indexOpLeft)
      if leftErr != nil:
        return leftErr
      let indexErr = compiler.compile(node.indexOpIndex)
      if indexErr != nil:
        return indexErr
      discard compiler.emit(OpIndex)

    of NodeType.NTReturnStatement:
      let err = compiler.compile(node.returnValue)
      if err != nil:
        return err

      discard compiler.emit(OpReturnValue)
    else:
      return nil
  return nil

method toBytecode*(compiler: var Compiler): Bytecode {.base.} =
  return Bytecode(
    instructions: compiler.currentInstructions(),
    constants: compiler.constants
  )
