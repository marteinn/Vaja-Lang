import unittest
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from obj import Obj, inspect, `$`
from compiler import newCompiler, compile, toBytecode
from vm import VM, newVM, runVM, lastPoppedStackElement
from helpers import TestValueType, TestValue, `==`, `$`

proc parseSource(source: string): Node =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()
  return program

proc testExpectedObj(expected: TestValue, actual: Obj) =
  check(expected == actual)

suite "vm tests":
  test "expected integer arthmetic":
    let tests: seq[(string, TestValue)] = @[
      ("1", TestValue(valueType: TVTInt, intValue: 1)),
      ("2", TestValue(valueType: TVTInt, intValue: 2)),
      ("1 + 2", TestValue(valueType: TVTInt, intValue: 3)),
      ("2 - 1", TestValue(valueType: TVTInt, intValue: 1)),
      ("2 * 2", TestValue(valueType: TVTInt, intValue: 4)),
      ("4 / 2", TestValue(valueType: TVTFloat, floatValue: 2.0)),
      ("-1", TestValue(valueType: TVTInt, intValue: -1)),
      ("-10", TestValue(valueType: TVTInt, intValue: -10)),
      ("-50 + 20", TestValue(valueType: TVTInt, intValue: -30)),
      ("((5 + 10) * 2 + -10) / 2", TestValue(valueType: TVTFloat, floatValue: 10.0)),
    ]

    for x in tests:
      let program = parseSource(x[0])
      var compiler = newCompiler()
      let compilerErr = compiler.compile(program)
      check(compilerErr == nil)

      var vm: VM = newVM(compiler.toBytecode())
      let vmErr = vm.runVM()
      check(vmErr == nil)
      let obj: Obj = vm.lastPoppedStackElement()

      testExpectedObj(x[1], obj)

  test "boolean expressions":
    let tests: seq[(string, TestValue)] = @[
      ("true", TestValue(valueType: TVTBool, boolValue: true)),
      ("false", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 < 2", TestValue(valueType: TVTBool, boolValue: true)),
      ("1 > 2", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 < 1", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 > 1", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 == 1", TestValue(valueType: TVTBool, boolValue: true)),
      ("1 == 2", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 != 1", TestValue(valueType: TVTBool, boolValue: false)),
      ("2 != 1", TestValue(valueType: TVTBool, boolValue: true)),
      ("true == true", TestValue(valueType: TVTBool, boolValue: true)),
      ("true == false", TestValue(valueType: TVTBool, boolValue: false)),
      ("true != false", TestValue(valueType: TVTBool, boolValue: true)),
      ("(2 > 1) == true", TestValue(valueType: TVTBool, boolValue: true)),
      ("not true", TestValue(valueType: TVTBool, boolValue: false)),
      ("not false", TestValue(valueType: TVTBool, boolValue: true)),
      ("not (2 > 1)", TestValue(valueType: TVTBool, boolValue: false)),
    ]

    for x in tests:
      let program = parseSource(x[0])
      var compiler = newCompiler()
      let compilerErr = compiler.compile(program)
      check(compilerErr == nil)

      var vm: VM = newVM(compiler.toBytecode())
      let vmErr = vm.runVM()
      check(vmErr == nil)
      let obj: Obj = vm.lastPoppedStackElement()

      testExpectedObj(x[1], obj)
