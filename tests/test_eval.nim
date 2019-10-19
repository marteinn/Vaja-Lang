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
  test "nil expression":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("nil", "nil"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

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
        ("(fn(x, y) -> x)(1, 2, 3)", "Function with arity 2 called with 3 arguments"),
        ("case (2) 1 -> 2 end", "No clause matching"),
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

  test "named function declaration":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("fn hello(a, b) 1 end; hello", "<function group>"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTFunctionGroup
      check evaluated.inspect() == testPair[1]

  test "function declaration":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("fn (a, b) 1 end", "fn (a, b) 1 end"),
        ("let a = fn () 1 end; a", "fn () 1 end"),
        ("let a = fn(x) -> x; a", "fn (x) x end"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTFunction
      check evaluated.inspect() == testPair[1]

  test "passing function as a argument":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("""let calc = fn(sum) -> sum(5)
calc(fn(x) -> x*2)
""", "10")
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "call expression":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("fn hello() 1 end; hello()", "1"),
        ("fn hello(x) x end; hello(2)", "2"),
        ("fn add(x, y) x+y end; add(2,3)", "5"),
        ("fn add(x, y) x+y end; let value = 5; add(value,3)", "8"),
        ("let add = fn(x, y) x+y end; add(1,2)", "3"),
        ("""fn a() 10 end; a()""", "10"),
        ("""fn a()
return 5
10
end; a()""", "5"),
        ("(fn (x) x end)(1)", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "return statements":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("return 1", "1"),
        ("return 2*2", "4"),
        ("""return 1
10""", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "return statement unwrap":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("fn a() return 1 end; a()", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTInteger
      check evaluated.inspect() == testPair[1]

  test "closure behaves":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("""fn myFunc(x)
return fn(y) -> x+y
end; myFunc(1)(2)""", "3"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTInteger
      check evaluated.inspect() == testPair[1]

  test "piping values to function call":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("""fn a(x) -> x + 1
fn b(x) -> x + 2
0 |> a() |> b()""", "3"),
      ("""fn a(x) -> x + 1
fn b(x) -> x + 2
fn c(x) -> x + 3
2 |> a() |> b() |> c()""", "8"),
    ("""fn a(x, y) -> x * y
fn b(x) -> x + 2
fn c(x) -> x + 3
2 |> a(5) |> b() |> c()""", "15"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTInteger
      check evaluated.inspect() == testPair[1]

  test "if statements":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("if (true) 1 else 2 end", "1"),
        ("if (false) 1 else 2 end", "2"),
        ("if (1 == 1) 1 end", "1"),
        ("if (1 == 2) 1 end", "nil"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "pattern matching":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("""
fn hello(1) -> 11
fn hello(2) -> 12
fn hello(name, 1) -> 13
fn hello(name, 2) -> 13
hello(1)""", "11"),
        ("""
fn hello(1) -> 21
fn hello(2) -> 22
hello(2)""", "22"),
      ("""
fn hello(name, 1) -> 31
fn hello(name, 2) -> 32
hello("tom", 1)""", "31"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "non matching function pattern matching":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("""
fn hello("tom waits") -> 1
fn hello("lou reed") -> 2
hello("john bolton")""", "Function is undefined"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTError
      check evaluated.inspect() == testPair[1]

  test "using _ or _ prefix will raise error":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("""
fn greet(_) -> _
greet("jane")""", "Invalid use of _, it represents a value to be ignored"),
      ("""
fn greet(_name) -> _name
greet("jane")""", "Invalid use of _name, it represents a value to be ignored"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTError
      check evaluated.inspect() == testPair[1]

  test "_ and _ prefix will be ignored":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("""
fn greet(_) -> "myval"
greet("jane")""", "myval"),
      ("""
fn greet(_name) -> "anotherval"
greet("jane")""", "anotherval"),
      ("""
fn greet(_, _) -> "myval"
greet("jane", "doe")""", "myval"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTString
      check evaluated.inspect() == testPair[1]

  test "case expression":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("""
case ("hello")
  "hello" -> 1
end
""", "1"),
        ("""
let a = "hi"
case (a)
  "hello" -> 1
  "hi" -> 2
  "howdy" -> 3
end
""", "2"),
        ("""
let a = "hello sir"
case (a)
  "hello" -> 1
  "hi" -> 2
  "howdy" -> 3
  _ -> 4
end
""", "4"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      #check evaluated.objType == ObjType.OTInteger
      check evaluated.inspect() == testPair[1]


  #test "function currying":
    #type
      #ExpectedEval = (string, string)
      #ExpectedEvals = seq[ExpectedEval]
    #var
      #tests: ExpectedEvals = @[
        #("fn a(x, y, z) -> x * y + z; a(1)(2)(3)", "5"),
      #]

    #for testPair in tests:
      #var evaluated: Obj = evalSource(testPair[0])
      #check evaluated.inspect() == testPair[1]
      #check evaluated.objType == ObjType.OTInteger
