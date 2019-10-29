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

suite "builtins regex tests":
  test "Regex.fromString":
    var
      tests: ExpectedEvals = @[
        ("""Regex.fromString("[0-9]")""", "<regex>"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Regex.contains":
    var
      tests: ExpectedEvals = @[
        ("""
let regex = "[0-9]" |> Regex.fromString()
Regex.contains(regex, "9")""", "true"),
        ("""
let regex = "[0-9]" |> Regex.fromString()
Regex.contains(regex, "M")""", "false"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "Regex.find":
    var
      tests: ExpectedEvals = @[
        ("""
let regex = "^(c)a(t) people" |> Regex.fromString()
Regex.find(regex, "cat people")""", "[c, t]"),
        ("""
let regex = "^(c)a(t) people" |> Regex.fromString()
Regex.find(regex, "HELLO")""", "[]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
