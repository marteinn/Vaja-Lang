import unittest
from lexer import newLexer, Lexer, nextToken, readCharacter
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode

proc parseSource(source:string): Node =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer = lexer)
    program: Node = parser.parseProgram()

  return program

suite "parser tests":
  test "test integer literal":
    var
      source: string = "1"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTIntegerLiteral
    check program.statements[0].toCode() == "1"

  test "test float literal":
    var
      source: string = "2.2"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTFloatLiteral
    check program.statements[0].toCode() == "2.2"

  test "test bool types":
    var
      source: string = "true"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTBoolean
    check program.statements[0].toCode() == "true"

  test "prefix parsing":
    type
      ExpectedParsing = (string, string)
      ExpectedTokens = seq[ExpectedParsing]
    var
      tests: ExpectedTokens = @[
        ("-1", "(-1)"),
        ("not true", "(not true)"),
        ("not (not true)", "(not (not true))"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "illegal prefix operators returns error":
    var
      source: string = "$1"
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Node = parser.parseProgram()

    discard program

    check len(parser.errors) == 1

  test "operator precedence":
    type
      ExpectedParsing = (string, string)
      ExpectedTokens = seq[ExpectedParsing]
    var
      tests: ExpectedTokens = @[
        ("true and not false", "(true and (not false))"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "influx parsing":
    type
      ExpectedParsing = (string, string)
      ExpectedTokens = seq[ExpectedParsing]
    var
      tests: ExpectedTokens = @[
        ("1 + 1", "(1 + 1)"),
        ("1 + 1 + 1", "((1 + 1) + 1)"),
        ("1 - 1", "(1 - 1)"),
        ("-1 + 1", "((-1) + 1)"),
        ("1 * 1", "(1 * 1)"),
        ("1 / 1", "(1 / 1)"),
        ("1 + 2 * 3", "(1 + (2 * 3))"),
        ("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
        ("5 % 5", "(5 % 5)"),
        ("6 ** 6", "(6 ** 6)"),
        ("\"hi\" & \"again\"", "(hi & again)"),
        ("true and false", "(true and false)"),
        ("true or false", "(true or false)"),
        ("1 == 2", "(1 == 2)"),
        ("1 != 2", "(1 != 2)"),
        ("1 > 2", "(1 > 2)"),
        ("1 >= 2", "(1 >= 2)"),
        ("1 < 2", "(1 < 2)"),
        ("1 <= 2", "(1 <= 2)"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "dentifier":
    var
      source: string = "a"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTIdentifier
    check program.statements[0].toCode() == "a"

  test "string":
    var
      source: string = """"hello""""
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTStringLiteral
    check program.statements[0].toCode() == "hello"

  test "variable assignment struct test":
    var
      source: string = "let a = 1"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTAssignStatement
    check program.statements[0].assignName.nodeType == NodeType.NTIdentifier
    check program.statements[0].assignName.identValue == "a"
    check program.statements[0].assignValue.nodeType == NodeType.NTIntegerLiteral
    check program.statements[0].assignValue.toCode() == "1"
    check program.statements[0].toCode() == "let a = 1"

  test "variable assignment variations":
    check parseSource("let a = b").toCode() == "let a = b"
    check parseSource("let a = true").toCode() == "let a = true"
    check parseSource("let a = 2.2").toCode() == "let a = 2.2"
    check parseSource("let a = \"string\"").toCode() == "let a = string"

  test "multiple assignments":
    var
      source: string = """let a = 1
let b = 2
let c = "hello"
"""
      program: Node = parseSource(source)
    check len(program.statements) == 3

  test "semicolon delimiter":
    check len(parseSource("1;2").statements) == 2
    check len(parseSource("let a = 1;2").statements) == 2
