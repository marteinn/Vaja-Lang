import unittest
from lexer import newLexer, Lexer, nextToken, readCharacter
from parser import Parser, newParser, parseProgram
from ast import Program, NodeType, toCode

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

  test "test prefix parsing":
    var
      source: string = "-1"
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Program = parser.parseProgram()

    check len(program.statements) == 1
    check program.statements[0].toCode() == "(-1)"
