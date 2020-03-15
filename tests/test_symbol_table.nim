import unittest
import tables

from symbol_table import
  newSymbolTable,
  newEnclosedSymbolTable,
  SymbolTable,
  Symbol,
  define,
  defineBuiltin,
  resolve,
  GLOBAL_SCOPE,
  LOCAL_SCOPE,
  FREE_SCOPE,
  BUILTIN_SCOPE,
  `$`,
  `==`

suite "symbol table tests":
  test "resolve builtins":
    var
      global: SymbolTable = newSymbolTable()
      local: SymbolTable = newEnclosedSymbolTable(global)

    let
      expected: seq[Symbol] = @[
        Symbol(name: "a", scope: BUILTIN_SCOPE, index: 0),
        Symbol(name: "b", scope: BUILTIN_SCOPE, index: 1),
        Symbol(name: "c", scope: BUILTIN_SCOPE, index: 2),
        Symbol(name: "d", scope: BUILTIN_SCOPE, index: 3),
      ]

    for index, symbol in expected:
      discard global.defineBuiltin(index, symbol.name)

    for symbol in expected:
      let resolvedSymbol: (Symbol, bool) = local.resolve(symbol.name)
      check(resolvedSymbol[0] == symbol)

  test "resolve local":
    var
      global: SymbolTable = newSymbolTable()
    discard global.define("a")
    discard global.define("b")

    var
      local: SymbolTable = newEnclosedSymbolTable(global)
    discard local.define("c")
    discard local.define("d")

    let
      expected: seq[Symbol] = @[
        Symbol(name: "a", scope: GLOBAL_SCOPE, index: 0),
        Symbol(name: "b", scope: GLOBAL_SCOPE, index: 1),
        Symbol(name: "c", scope: LOCAL_SCOPE, index: 0),
        Symbol(name: "d", scope: LOCAL_SCOPE, index: 1),
      ]

    for symbol in expected:
      let resolvedSymbol: (Symbol, bool) = local.resolve(symbol.name)
      check(resolvedSymbol[0] == symbol)

  test "resolve nested local":
    var
      global: SymbolTable = newSymbolTable()
    discard global.define("a")
    discard global.define("b")

    var
      local: SymbolTable = newEnclosedSymbolTable(global)
    discard local.define("c")
    discard local.define("d")

    var
      nestedLocal: SymbolTable = newEnclosedSymbolTable(local)
    discard nestedLocal.define("e")
    discard nestedLocal.define("f")

    let
      expected: seq[Symbol] = @[
        Symbol(name: "a", scope: GLOBAL_SCOPE, index: 0),
        Symbol(name: "b", scope: GLOBAL_SCOPE, index: 1),
        Symbol(name: "e", scope: LOCAL_SCOPE, index: 0),
        Symbol(name: "f", scope: LOCAL_SCOPE, index: 1),
      ]

    for symbol in expected:
      let resolvedSymbol: (Symbol, bool) = nestedLocal.resolve(symbol.name)
      check(resolvedSymbol[0] == symbol)

  test "define":
    let
      expected: Table[string, Symbol] = {
        "a": Symbol(name: "a", scope: GLOBAL_SCOPE, index: 0),
        "b": Symbol(name: "b", scope: GLOBAL_SCOPE, index: 1),
        "c": Symbol(name: "c", scope: LOCAL_SCOPE, index: 0),
        "d": Symbol(name: "d", scope: LOCAL_SCOPE, index: 1),
        "e": Symbol(name: "e", scope: LOCAL_SCOPE, index: 0),
        "f": Symbol(name: "f", scope: LOCAL_SCOPE, index: 1),
      }.toTable
    var
      global: SymbolTable = newSymbolTable()

    check(global.define("a") == expected["a"])
    check(global.define("b") == expected["b"])

    var
      local: SymbolTable = newEnclosedSymbolTable(global)

    check(local.define("c") == expected["c"])
    check(local.define("d") == expected["d"])

    var
      nestedLocal: SymbolTable = newEnclosedSymbolTable(local)

    check(nestedLocal.define("e") == expected["e"])
    check(nestedLocal.define("f") == expected["f"])

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

  test "resolve free":
    var
      global = newSymbolTable()

    discard global.define("a")
    discard global.define("b")

    var
      firstLocal: SymbolTable = newEnclosedSymbolTable(global)
    discard firstLocal.define("c")
    discard firstLocal.define("d")

    var
      secondLocal: SymbolTable = newEnclosedSymbolTable(firstLocal)
    discard secondLocal.define("e")
    discard secondLocal.define("f")

    let
      firstExpected: seq[Symbol] = @[
        Symbol(name: "a", scope: GLOBAL_SCOPE, index: 0),
        Symbol(name: "b", scope: GLOBAL_SCOPE, index: 1),
        Symbol(name: "c", scope: LOCAL_SCOPE, index: 0),
        Symbol(name: "d", scope: LOCAL_SCOPE, index: 1),
      ]

    for symbol in firstExpected:
      let resolvedSymbol: (Symbol, bool) = firstLocal.resolve(symbol.name)
      check(resolvedSymbol[0] == symbol)

    let
      secondExpected: seq[Symbol] = @[
        Symbol(name: "a", scope: GLOBAL_SCOPE, index: 0),
        Symbol(name: "b", scope: GLOBAL_SCOPE, index: 1),
        Symbol(name: "c", scope: FREE_SCOPE, index: 0),
        Symbol(name: "d", scope: FREE_SCOPE, index: 1),
        Symbol(name: "e", scope: LOCAL_SCOPE, index: 0),
        Symbol(name: "f", scope: LOCAL_SCOPE, index: 1),
      ]
      secondFreeExpected: seq[Symbol] = @[
        Symbol(name: "c", scope: LOCAL_SCOPE, index: 0),
        Symbol(name: "d", scope: LOCAL_SCOPE, index: 1),
      ]

    for symbol in secondExpected:
      let resolvedSymbol: (Symbol, bool) = secondLocal.resolve(symbol.name)
      check(resolvedSymbol[0] == symbol)

    for index, symbol in secondFreeExpected:
      let resolvedSymbol: Symbol = secondLocal.freeSymbols[index]
      check(resolvedSymbol == symbol)

  test "unrecoverable free":
    var
      global = newSymbolTable()
    discard global.define("a")

    var
      firstLocal: SymbolTable = newEnclosedSymbolTable(global)
    discard firstLocal.define("c")

    var
      secondLocal: SymbolTable = newEnclosedSymbolTable(firstLocal)
    discard secondLocal.define("e")
    discard secondLocal.define("f")

    let
      expected: seq[Symbol] = @[
        Symbol(name: "a", scope: GLOBAL_SCOPE, index: 0),
        Symbol(name: "c", scope: FREE_SCOPE, index: 0),
        Symbol(name: "e", scope: LOCAL_SCOPE, index: 0),
        Symbol(name: "f", scope: LOCAL_SCOPE, index: 1),
      ]

    for symbol in expected:
      let resolvedSymbol: (Symbol, bool) = secondLocal.resolve(symbol.name)
      check(resolvedSymbol[0] == symbol)

    let unreachableSymbols: seq[string] = @["b", "d"]
    for name in unreachableSymbols:
      let
        (_, ok) = secondLocal.resolve(name)
      check(ok == false)
