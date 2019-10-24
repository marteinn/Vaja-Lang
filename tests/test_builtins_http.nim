import unittest
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from obj import Obj, ObjType, Env, newEnv, inspect
from builtins_http import HttpServer
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
  test "Http.createServer":
    let
      tests: ExpectedEvals = @[
        ("Http.createServer()", "<native object>")
      ]
    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTNativeObject
      check evaluated.inspect() == testPair[1]

  test "Http.addRoutes":
    var
      tests: ExpectedEvals = @[
        ("""
let server = Http.createServer()
let handler = fn(req)
  return {
    "status": 200,
    "body": "Hello world"
  }
end
server |> Http.addRoutes([["/", handler]]); server""", "<native object>")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
      check evaluated.nativeValue of HttpServer
      let
        httpServer: HttpServer = cast[HttpServer](evaluated.nativeValue)
      check len(httpServer.routes) == 1

  test "That handlers are matched and returns proper response":
    var
      tests: ExpectedEvals = @[
        ("""
let handler = fn(req) -> {"status": 200, "body": "Hello world"}
Http.createServer() \
|> Http.addRoutes([["/", handler]]) \
|> Http.call("/", {}, {})""", "{status: 200, body: Hello world}")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTHashMap
      check evaluated.inspect() == testPair[1]

  test "That that proper status code are returned":
    var
      tests: ExpectedEvals = @[
        ("""
Http.createServer() \
|> Http.addRoutes([["/", fn(req) -> {"status": 201, "body": "Hello world"}]]) \
|> Http.call("/", {}, {})""", "{status: 201, body: Hello world}")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTHashMap
      check evaluated.inspect() == testPair[1]

  test "That that headers are returned":
    var
      tests: ExpectedEvals = @[
        ("""
let handler = fn(req)
  {
    "status": 201,
    "body": "Hello world",
    "headers": [
      ["Content-Type", "application/json"]
    ]
  }
end
Http.createServer() \
|> Http.addRoutes([["/", handler]]) \
|> Http.call("/", {}, {})""", "{status: 201, body: Hello world, headers: [[Content-Type, application/json]]}")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTHashMap
      check evaluated.inspect() == testPair[1]
