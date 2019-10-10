type
  TokenType* = enum
    # Types
    INT,
    FLOAT,
    STRING,
    TRUE,
    FALSE
    # Arithmetic
    PLUS,
    MINUS,
    SLASH,
    ASTERISK,
    # TODO: Modulo %
    # TODO: Floor? //
    # TODO: Exponent **
    # Special
    ILLEGAL,
    EOF,
    NEWLINE,
    SEMICOLON,
    LPAREN,
    RPAREN,
    # Operators
    LET,
    # Identifier
    IDENT,
    # Assignment
    ASSIGN,
    # Logical
    # TODO: AND,
    # TODO: OR,
    # TODO: NOT
    # Comparison
    EQ

type
  Token* = object
    tokenType*: TokenType
    literal*: string

proc newToken*(tokenType: TokenType, literal: string): Token =
  return Token(tokenType: tokenType, literal: literal)
