import unittest
from lexer import newLexer, Lexer, nextToken, readCharacter
from token import TokenType, Token

suite "lexer tests":
  test "common tokens are properly lexed":
    var
      source: string = """1+2
1-1
let a = 1
;
-1
2*3
2/3
"""
      lexer: Lexer = newLexer(source)
    type
      ExpectedTokenPair = (TokenType, string)
      ExpectedTokens = array[27, ExpectedTokenPair]
    let
      tokens: ExpectedTokens = [
        (TokenType.INT, "1"),
        (TokenType.PLUS, "+"),
        (TokenType.INT, "2"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.INT, "1"),
        (TokenType.MINUS, "-"),
        (TokenType.INT, "1"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.LET, "let"),
        (TokenType.IDENT, "a"),
        (TokenType.ASSIGN, "="),
        (TokenType.INT, "1"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.SEMICOLON, ";"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.MINUS, "-"),
        (TokenType.INT, "1"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.INT, "2"),
        (TokenType.ASTERISK, "*"),
        (TokenType.INT, "3"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.INT, "2"),
        (TokenType.SLASH, "/"),
        (TokenType.INT, "3"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.EOF, "")
      ]

    for expectedToken in tokens:
      var
        token: Token = lexer.nextToken()

      check(token.tokenType == expectedToken[0])
      check(token.literal == expectedToken[1])

  test "eof is set":
    var
      source: string = ""
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.EOF)

  test "whitespace are ignored":
    var
      source: string = "1 +  1"
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.INT)
    check(lexer.nextToken().tokenType == TokenType.PLUS)
    check(lexer.nextToken().tokenType == TokenType.INT)
    check(lexer.nextToken().tokenType == TokenType.EOF)

  test "bools are parsed":
    var
      source: string = """
true
false
"""
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.TRUE)
    check(lexer.nextToken().tokenType == TokenType.FALSE)
