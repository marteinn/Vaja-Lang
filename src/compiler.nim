from code import Instructions, OpCode, make, OpConstant
from obj import Obj, newInteger
from ast import Node, NodeType

type
  Compiler* = ref object
    instructions*: Instructions
    constants*: seq[Obj]
  Bytecode* = ref object
    instructions*: Instructions
    constants*: seq[Obj]

proc newCompiler*(): Compiler =
  return Compiler(instructions: @[], constants: @[])

method addInstruction(compiler: var Compiler, instructions: seq[byte]): int {.base.} =
  let posNewInstruction = len(compiler.instructions)
  compiler.instructions.add(instructions)
  return posNewInstruction

method emit*(compiler: var Compiler, op: OpCode, operands: seq[int]): int {.base.} =
  let instructions = make(op, operands)
  return compiler.addInstruction(instructions)

method addConstant*(compiler: var Compiler, obj: Obj): int {.base.} =
  compiler.constants.add(obj)
  return len(compiler.constants) - 1

method compile*(compiler: var Compiler, node: Node): Node {.base.} =
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
    of NodeType.NTInfixExpression:
      let errLeft = compiler.compile(node.infixLeft)
      if errLeft != nil:
        return errLeft
      let errRight = compiler.compile(node.infixRight)
      if errRight != nil:
        return errRight
    of NodeType.NTIntegerLiteral:
      let obj = newInteger(node.intValue)
      discard compiler.emit(OpConstant, @[compiler.addConstant(obj)])
    else:
      return nil
  return nil

method toBytecode*(compiler: Compiler): Bytecode {.base.} =
  return Bytecode(
    instructions: compiler.instructions,
    constants: compiler.constants
  )
