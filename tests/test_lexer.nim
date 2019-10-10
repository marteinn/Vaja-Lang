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
123
1.1
5%5
6**6
"""
      lexer: Lexer = newLexer(source)
    type
      ExpectedTokenPair = (TokenType, string)
      ExpectedTokens = array[39, ExpectedTokenPair]
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
        (TokenType.INT, "123"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.FLOAT, "1.1"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.INT, "5"),
        (TokenType.MODULO, "%"),
        (TokenType.INT, "5"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.INT, "6"),
        (TokenType.EXPONENT, "**"),
        (TokenType.INT, "6"),
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
    check(lexer.nextToken().tokenType == TokenType.NEWLINE)
    check(lexer.nextToken().tokenType == TokenType.FALSE)

  test "strings are parsed":
    var
      source: string = """"my string""""
      lexer: Lexer = newLexer(source)

    var nextToken: Token = lexer.nextToken()
    check(nextToken.tokenType == TokenType.STRING)
    check(nextToken.literal == "my string")

  test "function calls are properly parsed":
    var
      source: string = "hello()"
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.LPAREN)
    check(lexer.nextToken().tokenType == TokenType.RPAREN)
    check(lexer.nextToken().tokenType == TokenType.EOF)

  test "strings concatination":
    var
      source: string = """"my" & "string""""
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.STRING)
    check(lexer.nextToken().tokenType == TokenType.AMP)
    check(lexer.nextToken().tokenType == TokenType.STRING)
    check(lexer.nextToken().tokenType == TokenType.EOF)
