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

suite "builtins string tests":
  test "HashMap.len":
    var
      tests: ExpectedEvals = @[
        ("""HashMap.len({"name": 1, "another": 2})""", "2"),
        ("""HashMap.len({})""", "0"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.map":
    var
      tests: ExpectedEvals = @[
        ("""
HashMap.map(fn (_, value) -> value * 2, {"a": 1, "b": 2})""", "{a: 2, b: 4}"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.filter":
    var
      tests: ExpectedEvals = @[
        ("""
HashMap.filter(fn (key, _) -> key == "b", {"a": 1, "b": 2})""", "{b: 2}"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.reduce":
    var
      tests: ExpectedEvals = @[
        ("""
HashMap.reduce(
  fn (acc, curr, _key) -> acc + curr,
  0,
  {"a": 1, "b": 2, "c": 3}
)""", "6"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.toArray":
    var
      tests: ExpectedEvals = @[
        ("""HashMap.toArray({"name": 1, "another": 2})""", "[[name, 1], [another, 2]]"),
        ("""HashMap.toArray({})""", "[]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.insert":
    var
      tests: ExpectedEvals = @[
        ("""{} |> HashMap.insert("name", 1)""", "{name: 1}"),
        ("""
let a = {}
let b = HashMap.insert("name", 1, a)
a""", "{}"),
        ("""
let a = {}
let b = HashMap.insert("name", 1, a)
b""", "{name: 1}"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.remove":
    var
      tests: ExpectedEvals = @[
        ("""{"a": 1} |> HashMap.remove("a")""", "{}"),
        ("""
let a = {"name": 1}
let b = HashMap.remove("name", a)
a""", "{name: 1}"),
        ("""
let a = {"name": 1}
let b = HashMap.remove("name", a)
b""", "{}"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.update":
    var
      tests: ExpectedEvals = @[
        ("""{"a": 1} |> HashMap.update("a", 2)""", "{a: 2}"),
        ("""
let a = {"name": 1}
let b = HashMap.update("name", 2, a)
a""", "{name: 1}"),
        ("""
let a = {"name": 1}
let b = HashMap.update("name", 2, a)
b""", "{name: 2}"),
        ("""{"a": 1} |> HashMap.update("b", 2)""", "Key b not found"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.empty":
    var
      tests: ExpectedEvals = @[
        ("""HashMap.empty()""", "{}"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.hasKey":
    var
      tests: ExpectedEvals = @[
        ("""
{"name": 1} |> HashMap.hasKey("name")
""", "true"),
        ("""
{"name": 1} |> HashMap.hasKey("notfound")
""", "false"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "HashMap.get":
    var
      tests: ExpectedEvals = @[
        ("""HashMap.get("name", nil, {"name": 1, "another": 2})""", "1"),
        ("""HashMap.get("name2", nil, {"name": 1, "another": 2})""", "nil"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
