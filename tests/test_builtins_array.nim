import unittest
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from obj import Obj, ObjType, Env, newEnv, inspect
from evaluator import eval

proc evalSource(source:string): Obj =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer = lexer)
    program: Node = parser.parseProgram()
    env: Env = newEnv()
  return eval(program, env)

suite "builtins array tests":
  test "Array.len":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("Array.len([1, 2, 3])", "3"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.head":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("Array.head([1, 2, 3])", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.last":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("Array.last([1, 2, 3])", "3"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.map":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("Array.map(fn (x) -> x*2, [1, 2, 3])","[2, 4, 6]"),
        ("fn multi(x) -> x*2; Array.map(multi, [1, 2, 3])","[2, 4, 6]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
