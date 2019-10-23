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

type
  ExpectedEval = (string, string)
  ExpectedEvals = seq[ExpectedEval]

suite "builtins array tests":
  test "Array.len":
    var
      tests: ExpectedEvals = @[
        ("Array.len([1, 2, 3])", "3"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.head":
    var
      tests: ExpectedEvals = @[
        ("Array.head([1, 2, 3])", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.last":
    var
      tests: ExpectedEvals = @[
        ("Array.last([1, 2, 3])", "3"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.map":
    var
      tests: ExpectedEvals = @[
        ("Array.map(fn (x) -> x*2, [1, 2, 3])","[2, 4, 6]"),
        ("fn multi(x) -> x*2; Array.map(multi, [1, 2, 3])","[2, 4, 6]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.reduce":
    var
      tests: ExpectedEvals = @[
        ("Array.reduce(fn (acc, curr) -> acc + curr, 1, [1, 2, 3])", "7"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.filter":
    var
      tests: ExpectedEvals = @[
        ("Array.filter(fn (x) -> x == 1, [1, 0, 1])", "[1, 1]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.push":
    var
      tests: ExpectedEvals = @[
        ("Array.push(4, [1, 2, 3])", "[1, 2, 3, 4]"),
        ("let a = [1, 2, 3]; Array.push(4, a); a", "[1, 2, 3]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.deleteAt":
    var
      tests: ExpectedEvals = @[
        ("Array.deleteAt(0, [1, 2, 3])", "[2, 3]"),
        ("let a = [1, 2, 3]; Array.deleteAt(1, a); a", "[1, 2, 3]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.append":
    var
      tests: ExpectedEvals = @[
        ("Array.append([1, 2], [3, 4])", "[1, 2, 3, 4]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.replaceAt":
    var
      tests: ExpectedEvals = @[
        ("Array.replaceAt(1, 55, [1, 2])", "[1, 55]"),
        ("let a = [1, 2]; Array.replaceAt(1, 55, a); a", "[1, 2]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Array.tail":
    var
      tests: ExpectedEvals = @[
        ("Array.tail([1, 2, 3, 4])", "[2, 3, 4]"),
        ("let a = [1, 2]; Array.tail(a); a", "[1, 2]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
