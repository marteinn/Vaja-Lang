import os
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

suite "builtins json tests":
  test "JSON.toJSON":
    var
      tests: ExpectedEvals = @[
        ("JSON.toJSON(1)", "1"),
        ("JSON.toJSON([1, true, 5.5])", "[1,true,5.5]"),
        ("""JSON.toJSON([1, [true], 5.5, "hej"])""", """[1,[true],5.5,"hej"]"""),
        ("""JSON.toJSON({"random": 1})""", """{"random":1}"""),
        ("JSON.toJSON(nil)", "null"),
        ("JSON.toJSON(fn(x) -> 1)", "null"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == OTString
      check evaluated.inspect() == testPair[1]

  test "JSON.fromJSON":
    var
      tests: ExpectedEvals = @[
        ("""JSON.fromJSON("1")""", "1"),
        ("""JSON.fromJSON("true")""", "true"),
        ("""JSON.fromJSON("false")""", "false"),
        ("""JSON.fromJSON("1.1")""", "1.1"),
        ("""JSON.fromJSON("[1, true, 1.1]")""", "[1, true, 1.1]"),

        ("""JSON.fromJSON("\"hej\"")""", "hej"),
        ("""JSON.fromJSON("[1, [true], 5.5, \"hej\"]")""", """[1, [true], 5.5, hej]"""),
        ("""JSON.fromJSON("{\"random\": 1}")""", """{random: 1}"""),
        ("""JSON.fromJSON("null")""", """nil"""),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
