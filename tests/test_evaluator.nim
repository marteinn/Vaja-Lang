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

suite "eval tests":
  test "int expressions":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("1", "1"),
        ("1+1", "2"),
        ("1-1", "0"),
        ("5*2", "10"),
        ("5/2", "2.5"),
        ("5%5", "0"),
        ("5**5", "3125"),
        ("-1", "-1"),
        ("1 == 1", "true"),
        ("1 != 1", "false"),
        ("1 > 1", "false"),
        ("1 >= 1", "true"),
        ("5 < 10", "true"),
        ("10 < 5", "false"),
        ("5 <= 5", "true"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "float expressions":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("2.2", "2.2"),
        ("2.2 + 1.1", "3.3"),
        ("1 - 0.5", "0.5"),
        ("1*5.5", "5.5"),
        ("10/2", "5.0"),
        ("-1.1", "-1.1"),
        ("1.0 == 1.0", "true"),
        ("1.0 != 1.0", "false"),
        ("1.0 > 1.0", "false"),
        ("1.0 >= 1.0", "true"),
        ("5.0 < 10.0", "true"),
        ("10.0 < 5.0", "false"),
        ("5.0 <= 5.0", "true"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "string expressions":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("\"hello\"", "hello"),
        ("\"hi\" & \"again\"", "hiagain"),
        ("\"hi\" == \"hi\"", "true"),
        ("\"hi\" != \"hi\"", "false"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "assignments":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("let a = 1", ""),
        ("let a = 5; a", "5"),
        ("let a = 7; let b = a; b", "7"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "error handling":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("a", "Name a is not defined"),
        ("1 & 1", "Unknown infix operator &"),
        ("1 & 1; 5", "Unknown infix operator &"),
        ("\"a\" + \"b\"", "Unknown infix operator +"),
        ("-true", "Prefix operator - does not support type OTBoolean"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTError
      check evaluated.inspect() == testPair[1]

  test "bool prefix operations":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("not true", "false"),
        ("not not true", "true"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTBoolean
      check evaluated.inspect() == testPair[1]

  test "bool infix operations":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("true and true", "true"),
        ("false and true", "false"),
        ("let a = true; let b = true; a and b", "true"),
        ("false or true", "true"),
        ("false or false", "false"),
        ("false == false", "true"),
        ("false != false", "false"),
        #("(true and false) or false", "true"),
        #("function a () return false end; a() or false", False),
        #("function a () return true end; a() and true", True),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTBoolean
      check evaluated.inspect() == testPair[1]
