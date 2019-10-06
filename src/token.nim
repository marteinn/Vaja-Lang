type
  TokenType* = enum
    INT,
    PLUS,
    MINUS,
    ILLEGAL,
    EOF,
    NEWLINE,
    LET,
    ASSIGN,
    IDENT,
    SEMICOLON

type 
  Token* = object
    tokenType*: TokenType
    literal*: string

proc newToken*(tokenType: TokenType, literal: string): Token =
  return Token(tokenType: tokenType, literal: literal)
