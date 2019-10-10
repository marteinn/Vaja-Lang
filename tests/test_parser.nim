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
    var
      source: string = "-1"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].toCode() == "(-1)"

  test "illegal prefix operators returns error":
    var
      source: string = "$1"
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Node = parser.parseProgram()

    discard program

    check len(parser.errors) == 1

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
