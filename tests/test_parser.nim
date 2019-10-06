import unittest
from lexer import newLexer, Lexer, nextToken, readCharacter
from parser import Parser, newParser, parseProgram
from ast import Program, NodeType, toCode

proc parseSource(source:string): Program =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer = lexer)
    program: Program = parser.parseProgram()

  return program

suite "parser tests":
  test "test integer literal":
    var
      source: string = "1"
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Program = parser.parseProgram()

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTIntegerLiteral
    check program.statements[0].toCode() == "1"

  test "prefix parsing":
    var
      source: string = "-1"
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Program = parser.parseProgram()

    check len(program.statements) == 1
    check program.statements[0].toCode() == "(-1)"

  test "illegal prefix operators returns error":
    var
      source: string = "$1"
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Program = parser.parseProgram()

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
      ]
    for testPair in tests:
      var program: Program = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]


