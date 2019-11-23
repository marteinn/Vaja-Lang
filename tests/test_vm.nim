import unittest
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode

proc parseSource(source: string): Node =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()
  return program
