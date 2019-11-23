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
    TVTFloat
  TestValue* = ref object
    case valueType*: TestValueType
      of TVTInt: intValue*: int
      of TVTFloat: floatValue*: float

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

proc testFloatObj(expected: float, actual: Obj): bool =
  if actual.floatValue != expected:
    return false
  return true

proc testExpectedObj(expected: TestValue, actual: Obj) =
  case expected.valueType:
    of TVTInt:
      check(testIntObj(expected.intValue, actual))
    of TVTFloat:
      check(testFloatObj(expected.floatValue, actual))

suite "vm tests":
  test "expected intrger arthmetic":
    let tests: seq[(string, TestValue)] = @[
      ("1", TestValue(valueType: TVTInt, intValue: 1)),
      ("2", TestValue(valueType: TVTInt, intValue: 2)),
      ("1 + 2", TestValue(valueType: TVTInt, intValue: 3)),
      ("2 - 1", TestValue(valueType: TVTInt, intValue: 1)),
      ("2 * 2", TestValue(valueType: TVTInt, intValue: 4)),
      ("4 / 2", TestValue(valueType: TVTFloat, floatValue: 2.0)),
    ]

    for x in tests:
      let program = parseSource(x[0])
      var compiler = newCompiler()
      let compilerErr = compiler.compile(program)

      var vm: VM = newVM(compiler.toBytecode())
      let vmErr = vm.runVM()
      let obj: Obj = vm.lastPoppedStackElement()

      testExpectedObj(x[1], obj)
