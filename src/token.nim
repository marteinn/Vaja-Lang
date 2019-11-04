type
  TokenType* = enum
    # Types
    INT,
    FLOAT,
    STRING,
    TRUE,
    FALSE,
    NIL,
    # Arithmetic
    PLUS,
    MINUS,
    SLASH,
    ASTERISK,
    MODULO,
    EXPONENT,
    # TODO: Floor? //
    # Special
    ILLEGAL,
    EOF,
    NEWLINE,
    SEMICOLON,
    COMMA,
    COLON,
    LPAREN,
    RPAREN,
    LBRACKET,
    RBRACKET,
    LBRACE,
    RBRACE,
    AMP,
    PLUSPLUS,
    DOT,
    RETURN,
    RARROW,       # ->
    DOUBLELT,     # <<
    DOLLAR,
    PIPERARROW,   # |>
    PIPELARROW,   # <|
    IF,
    ELSE,
    CASE,
    OF,
    COMMENT,         # #
    # Loading
    IMPORT,
    FROM,
    # Operators
    LET,
    FUNCTION,
    END,
    # Identifier
    IDENT,
    # Assignment
    ASSIGN,
    # Logical
    AND,
    OR,
    NOT,
    BANG,
    # Comparison
    EQ,
    NOT_EQ,
    GT,
    GTE,
    LT,
    LTE

type
  Token* = object
    tokenType*: TokenType
    literal*: string

proc newToken*(tokenType: TokenType, literal: string): Token =
  return Token(tokenType: tokenType, literal: literal)

proc newEmptyToken*(): Token =
  return Token()
