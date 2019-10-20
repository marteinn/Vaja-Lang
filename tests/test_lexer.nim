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
true and true
true or false
not true
return false
$
|>
nil
add5
_
_ignored
case
"""
      lexer: Lexer = newLexer(source)
    type
      ExpectedTokenPair = (TokenType, string)
      ExpectedTokens = seq[ExpectedTokenPair]
    let
      tokens: ExpectedTokens = @[
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
        (TokenType.TRUE, "true"),
        (TokenType.AND, "and"),
        (TokenType.TRUE, "true"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.TRUE, "true"),
        (TokenType.OR, "or"),
        (TokenType.FALSE, "false"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.NOT, "not"),
        (TokenType.TRUE, "true"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.RETURN, "return"),
        (TokenType.FALSE, "false"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.DOLLAR, "$"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.PIPERARROW, "|>"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.NIL, "nil"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.IDENT, "add5"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.IDENT, "_"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.IDENT, "_ignored"),
        (TokenType.NEWLINE, "\n"),
        (TokenType.CASE, "case"),
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

  test "regular function construction":
    var
      source: string = "fn hello(a, b) let a = 1 end"
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.FUNCTION)
    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.LPAREN)
    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.COMMA)
    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.RPAREN)
    check(lexer.nextToken().tokenType == TokenType.LET)
    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.ASSIGN)
    check(lexer.nextToken().tokenType == TokenType.INT)
    check(lexer.nextToken().tokenType == TokenType.END)
    check(lexer.nextToken().tokenType == TokenType.EOF)

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

  test "passing string to function call":
    var
      source: string = """a("hello")"""
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.LPAREN)
    check(lexer.nextToken().tokenType == TokenType.STRING)
    check(lexer.nextToken().tokenType == TokenType.RPAREN)
    check(lexer.nextToken().tokenType == TokenType.EOF)

  test "comparison operators":
    var
      source: string = """
==
!=
>
>=
<
<=
"""
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.EQ)
    discard lexer.nextToken() # newline
    check(lexer.nextToken().tokenType == TokenType.NOT_EQ)
    discard lexer.nextToken() # newline
    check(lexer.nextToken().tokenType == TokenType.GT)
    discard lexer.nextToken() # newline
    check(lexer.nextToken().tokenType == TokenType.GTE)
    discard lexer.nextToken() # newline
    check(lexer.nextToken().tokenType == TokenType.LT)
    discard lexer.nextToken() # newline
    check(lexer.nextToken().tokenType == TokenType.LTE)

  test "lexing arrow functions":
    var
      source: string = "fn(x) -> x"
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.FUNCTION)
    check(lexer.nextToken().tokenType == TokenType.LPAREN)
    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.RPAREN)
    check(lexer.nextToken().tokenType == TokenType.RARROW)
    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.EOF)

  test "lexing if else statement":
    var
      source: string = "if (true) 1 else 0 end"
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.IF)
    check(lexer.nextToken().tokenType == TokenType.LPAREN)
    check(lexer.nextToken().tokenType == TokenType.TRUE)
    check(lexer.nextToken().tokenType == TokenType.RPAREN)
    check(lexer.nextToken().tokenType == TokenType.INT)
    check(lexer.nextToken().tokenType == TokenType.ELSE)
    check(lexer.nextToken().tokenType == TokenType.INT)
    check(lexer.nextToken().tokenType == TokenType.END)
    check(lexer.nextToken().tokenType == TokenType.EOF)

  test "lexing case statement":
    var
      source: string = """case (true)
  of true -> "hi"
  of false -> "do"
  of _ -> "anything"
end
"""
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.CASE)
    check(lexer.nextToken().tokenType == TokenType.LPAREN)
    check(lexer.nextToken().tokenType == TokenType.TRUE)
    check(lexer.nextToken().tokenType == TokenType.RPAREN)
    check(lexer.nextToken().tokenType == TokenType.NEWLINE)
    check(lexer.nextToken().tokenType == TokenType.OF)
    check(lexer.nextToken().tokenType == TokenType.TRUE)
    check(lexer.nextToken().tokenType == TokenType.RARROW)
    check(lexer.nextToken().tokenType == TokenType.STRING)
    check(lexer.nextToken().tokenType == TokenType.NEWLINE)
    check(lexer.nextToken().tokenType == TokenType.OF)
    check(lexer.nextToken().tokenType == TokenType.FALSE)
    check(lexer.nextToken().tokenType == TokenType.RARROW)
    check(lexer.nextToken().tokenType == TokenType.STRING)
    check(lexer.nextToken().tokenType == TokenType.NEWLINE)
    check(lexer.nextToken().tokenType == TokenType.OF)
    check(lexer.nextToken().tokenType == TokenType.IDENT)
    check(lexer.nextToken().tokenType == TokenType.RARROW)
    check(lexer.nextToken().tokenType == TokenType.STRING)
    check(lexer.nextToken().tokenType == TokenType.NEWLINE)
    check(lexer.nextToken().tokenType == TokenType.END)

  test "array tokens":
    var
      source: string = "[1, 2, 3]"
      lexer: Lexer = newLexer(source)

    check(lexer.nextToken().tokenType == TokenType.LBRACKET)
    check(lexer.nextToken().tokenType == TokenType.INT)
    check(lexer.nextToken().tokenType == TokenType.COMMA)
    check(lexer.nextToken().tokenType == TokenType.INT)
    check(lexer.nextToken().tokenType == TokenType.COMMA)
    check(lexer.nextToken().tokenType == TokenType.INT)
    check(lexer.nextToken().tokenType == TokenType.RBRACKET)
