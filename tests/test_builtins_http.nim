import unittest
import tables
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

  test "Http.addHandler":
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
server |> Http.addHandler(handler); server""", "<native object>")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
      check evaluated.nativeValue of HttpServer
      let
        httpServer: HttpServer = cast[HttpServer](evaluated.nativeValue)
      check httpServer.handler != nil

  test "That handler returns proper response":
    var
      tests: ExpectedEvals = @[
        ("""
let handler = fn(req) -> {"status": 200, "body": "Hello world"}
Http.createServer() \
|> Http.addHandler(handler) \
|> Http.call("/", "get", "", [])""", "{status: 200, body: Hello world}")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTHashMap
      check evaluated.hashMapElements["response"].inspect() == testPair[1]

  test "That that proper status code are returned":
    var
      tests: ExpectedEvals = @[
        ("""
let handler = fn(req) -> {"status": 201, "body": "Hello world"}
Http.createServer() \
|> Http.addHandler(handler) \
|> Http.call("/", "get", "", [])""", "{status: 201, body: Hello world}")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTHashMap
      check evaluated.hashMapElements["response"].inspect() == testPair[1]

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
|> Http.addHandler(handler) \
|> Http.call("/", "get", "", [])""", "{status: 201, body: Hello world, headers: [[Content-Type, application/json]]}")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTHashMap
      check evaluated.hashMapElements["response"].inspect() == testPair[1]

  test "Mapping request data to handler contains proper data":
    var
      tests: ExpectedEvals = @[
        ("""
let handler = fn(req) -> {"status": 201, "body": "Hello world"}
Http.createServer() \
|> Http.addHandler(handler) \
|> Http.call(
  "https://example.com:8080/about?s=1",
  "get",
  "req body", [
    ["user-agent", "curl/7.54.0"],
    ["host", "localhost:8080"]
  ]
)""",
        "{hostname: example.com, scheme: https, path: /about, port: 8080, anchor: , query: s=1, method: get, body: req body, headers: [[user-agent, curl/7.54.0], [host, localhost:8080]], protocol: {protocol: HTTP/1.1, major: 1, minor: 1}}")
      ]

    for testPair in tests:
      let evaluated: Obj = evalSource(testPair[0])
      check evaluated.objType == ObjType.OTHashMap
      check evaluated.hashMapElements["request"].inspect() == testPair[1]
