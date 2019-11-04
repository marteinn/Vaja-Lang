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

suite "eval tests":
  test "nil expression":
    var
      tests: ExpectedEvals = @[
        ("nil", "nil"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "int expressions":
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
    var
      tests: ExpectedEvals = @[
        ("\"hello\"", "hello"),
        ("\"hi\" ++ \"again\"", "hiagain"),
        ("\"hi\" == \"hi\"", "true"),
        ("\"hi\" != \"hi\"", "false"),
        ("\"hi\" != \"hi\"", "false"),
        ("\"\"", ""),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "array expression":
    var
      tests: ExpectedEvals = @[
        ("[1, 2, 3]", "[1, 2, 3]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "array index":
    var
      tests: ExpectedEvals = @[
        ("let a = [1, 2, 3]; a[0]", "1"),
        ("let a = [1, 2, 3]; let key = 1; a[key]", "2"),
        ("[1, 2, 3][2]", "3"),
        ("[1, 2, 3].0", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]


  test "array infix operations":
    var
      tests: ExpectedEvals = @[
        ("[1] ++ [2]", "[1, 2]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "hashmap expression":
    var
      tests: ExpectedEvals = @[
        ("""{"monday": 1}""", "{monday: 1}"),
        ("""let a = "today";{a: 1}""", "{today: 1}"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "hashmap index":
    var
      tests: ExpectedEvals = @[
        ("""let a = {"monday": 1}; a.monday""", "1"),
        ("""let a = {"monday": 1}; a["monday"]""", "1"),
        ("""let a = {"monday": 1}; let key = "monday"; a[key]""", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "assignments":
    var
      tests: ExpectedEvals = @[
        ("let a = 1", ""),
        ("let a = 5; a", "5"),
        ("let a = 7; let b = a; b", "7"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "re-assigning is not allowed":
    var
      tests: ExpectedEvals = @[
        ("""
let a = 1
let a = 2
a""", "Variable a cannot be reassigned"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "destructuring assignment on array":
    var
      tests: ExpectedEvals = @[
        ("let f = [1, 2]; let [a, b] = f; a", "1"),
        ("let f = [1, 2]; let [_, b] = f; b", "2"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "error handling":
    var
      tests: ExpectedEvals = @[
        ("a", "Name a is not defined"),
        ("1 & 1", "Unknown infix operator &"),
        ("1 & 1; 5", "Unknown infix operator &"),
        ("\"a\" + \"b\"", "Unknown infix operator +"),
        ("-true", "Prefix operator - does not support type OTBoolean"),
        ("(fn(x, y) -> x)(1, 2, 3)", "Function with arity 2 called with 3 arguments"),
        ("case (2) of 1 -> 2 end", "No clause matching"),
        ("cat(1)", "Name cat is not defined"),
        ("cat.name", "Index operation is not supported"),
        ("""{"b": 1}.name""", "Key name not found"),
        ("""{a: 1}""", "Only string indexes are allowed, found OTError"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTError
      check evaluated.inspect() == testPair[1]

  test "bool prefix operations":
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
    var
      tests: ExpectedEvals = @[
        ("fn hello(a, b) 1 end; hello", "<function group>"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTFunctionGroup
      check evaluated.inspect() == testPair[1]

  test "function declaration":
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
    var
      tests: ExpectedEvals = @[
        ("fn a() return 1 end; a()", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTInteger
      check evaluated.inspect() == testPair[1]

  test "closure behaves":
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

  test "function application left to right":
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

  test "function application right to left":
    var
      tests: ExpectedEvals = @[
        ("""fn a(x) -> x + 1
fn b(x) -> x + 2
b() <| a() <| 0""", "3"),
      ("""fn a(x) -> x + 1
fn b(x) -> x + 2
fn c(x) -> x + 3
c() <| b() <| a() <| 2""", "8"),
    ("""fn a(x, y) -> x * y
fn b(x) -> x + 2
fn c(x) -> x + 3
c() <| b() <| a(5) <| 2""", "15"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTInteger
      check evaluated.inspect() == testPair[1]

  test "if statements":
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
    var
      tests: ExpectedEvals = @[
        ("""
case ("hello")
  of "hello" -> 1
end
""", "1"),
        ("""
let a = "hi"
case (a)
  of "hello" -> 1
  of "hi" -> 2
  of "howdy" -> 3
end
""", "2"),
        ("""
let a = "hello sir"
case (a)
  of "hello" -> 1
  of "hi" -> 2
  of "howdy" -> 3
  of _ -> 4
end
""", "4"),
        ("""
let a = "hello"
case (a)
  of "hello" ->
    let value = 1
    value
  of "hi" -> 2
end
""", "1"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  #test "function currying":
    #var
      #tests: ExpectedEvals = @[
        #("fn a(x, y, z) -> x * y + z; a(1)(2)(3)", "5"),
      #]

    #for testPair in tests:
      #var evaluated: Obj = evalSource(testPair[0])
      #check evaluated.inspect() == testPair[1]
      #check evaluated.objType == ObjType.OTInteger

  test "builtin: type":
    var
      tests: ExpectedEvals = @[
        ("type(1)", "integer"),
        ("type(1.1)", "float"),
        ("""type("hello")""", "string"),
        ("type(true)", "boolean"),
        ("type(nil)", "nil"),
        ("type([1, 2])", "array"),
        ("type({})", "hashmap"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "builtin: print":
    var
      tests: ExpectedEvals = @[
        ("print(1)", "nil"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated == nil

  test "builtin: identity":
    var
      tests: ExpectedEvals = @[
        ("""identity(1)""", "1"),
        ("""identity(true)""", "true"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "builtin: always":
    var
      tests: ExpectedEvals = @[
        ("""let a = always(1); a()""", "1"),
        ("""let a = always([1,2]); a()""", "[1, 2]"),
        ("""let a = always(false); a()""", "false"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "function composition R->L":
    var
      tests: ExpectedEvals = @[
      ("""fn a(x) -> x + 1
fn b(x) -> x + 2
let sum = a << b
sum(1)""", "4"),
    ("""fn a(x) -> x + 1
fn b(x) -> x + 2
fn c(x) -> x * 2
let sum = a << b << c
sum(2)""", "7"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTInteger
      check evaluated.inspect() == testPair[1]

  test "function composition L->R":
    var
      tests: ExpectedEvals = @[
      ("""fn a(x) -> x + 1
fn b(x) -> x + 2
let sum = a >> b
sum(1)""", "4"),
    ("""fn a(x) -> x + 1
fn b(x) -> x + 2
fn c(x) -> x * 2
let sum = a >> b >> c
sum(2)""", "10"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTInteger
      check evaluated.inspect() == testPair[1]
