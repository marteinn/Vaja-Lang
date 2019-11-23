import unittest
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from obj import Obj, inspect
from compiler import newCompiler, compile, toBytecode
from vm import VM, newVM, runVM, lastPoppedStackElement

type
  TestValueType* = enum
    TVTInt
  TestValue* = ref object
    case valueType*: TestValueType
      of TVTInt: intValue*: int

proc parseSource(source: string): Node =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()
  return program

proc testIntObj(expected: int, actual: Obj): bool =
  if actual.intValue != expected:
    return false
  return true

proc testExpectedObj(expected: TestValue, actual: Obj) =
  case expected.valueType:
    of TVTInt:
      check(testIntObj(expected.intValue, actual))

suite "vm tests":
  test "expected obj":
    let tests: seq[(string, TestValue)] = @[
      ("1", TestValue(valueType: TVTInt, intValue: 1)),
      ("2", TestValue(valueType: TVTInt, intValue: 2)),
      ("1 + 2", TestValue(valueType: TVTInt, intValue: 3)),
    ]

    for x in tests:
      let program = parseSource(x[0])
      var compiler = newCompiler()
      let compilerErr = compiler.compile(program)

      var vm: VM = newVM(compiler.toBytecode())
      let vmErr = vm.runVM()
      let obj: Obj = vm.lastPoppedStackElement()

      testExpectedObj(x[1], obj)
