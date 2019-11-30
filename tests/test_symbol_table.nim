import unittest
import tables

from symbol_table import
  newSymbolTable,
  SymbolTable,
  Symbol,
  define,
  resolve,
  GLOBAL_SCOPE,
  `$`,
  `==`

suite "symbol table tests":
  test "define":
    let
      expected: Table[string, Symbol] = {
        "a": Symbol(name: "a", scope: GLOBAL_SCOPE, index: 0),
        "b": Symbol(name: "b", scope: GLOBAL_SCOPE, index: 1),
      }.toTable
    var
      global: SymbolTable = newSymbolTable()

    check(global.define("a") == expected["a"])
    check(global.define("b") == expected["b"])

  test "resolve":
    var
      global = newSymbolTable()

    discard global.define("a")
    discard global.define("b")

    let
      expected: seq[Symbol] = @[
        Symbol(name: "a", scope: GLOBAL_SCOPE, index: 0),
        Symbol(name: "b", scope: GLOBAL_SCOPE, index: 1),
      ]

    for symbol in expected:
      let resolvedSymbol: (Symbol, bool) = global.resolve(symbol.name)
      check(resolvedSymbol[0] == symbol)
