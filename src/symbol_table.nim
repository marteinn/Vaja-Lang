import tables
import strformat

type
  SymbolScope* = string

const
  GLOBAL_SCOPE*: SymbolScope = "GLOBAL"
  LOCAL_SCOPE*: SymbolScope = "LOCAL"
  BUILTIN_SCOPE*: SymbolScope = "BUILTIN"

type
  Symbol* = ref object
    name*: string
    scope*: SymbolScope
    index*: int
  SymbolTable* = ref object
    outer*: SymbolTable
    store*: Table[string, Symbol]
    numDefinitions*: int

proc newSymbolTable*(): SymbolTable =
  let store: Table[string, Symbol] = initTable[string, Symbol]()
  return SymbolTable(store: store, numDefinitions: 0)

proc newEnclosedSymbolTable*(outerSymbolTable: SymbolTable): SymbolTable =
  let
    store: Table[string, Symbol] = initTable[string, Symbol]()
    symbolTable = SymbolTable(store: store, numDefinitions: 0)
  symbolTable.outer = outerSymbolTable
  return symbolTable

proc `$`*(symbol: Symbol): string =
  if isNil(symbol):
    return "nil"
  return fmt"name: {symbol.name}, scope: {symbol.scope}, index: {symbol.index}"

proc `==`*(symbolA: Symbol, symbolB: Symbol): bool =
  if isNil(symbolA) or isNil(symbolB):
    return false

  return (
    symbolA.name == symbolB.name and
    symbolA.scope == symbolB.scope and
    symbolA.index == symbolB.index
  )

method define*(symbolTable: var SymbolTable, name: string): Symbol {.base.} =
  let symbol: Symbol = Symbol(
    name: name,
    index: symbolTable.numDefinitions
  )

  if symbolTable.outer == nil:
    symbol.scope = GLOBAL_SCOPE
  else:
    symbol.scope = LOCAL_SCOPE

  symbolTable.store[name] = symbol
  symbolTable.numDefinitions = symbolTable.numDefinitions + 1

  return symbol

method defineBuiltin*(symbolTable: var SymbolTable, index: int, name: string): Symbol {.base.} =
  let symbol: Symbol = Symbol(
    name: name,
    index: index,
    scope: BUILTIN_SCOPE,
  )
  symbolTable.store[name] = symbol
  return symbol

method resolve*(symbolTable: var SymbolTable, name: string): (Symbol, bool) {.base.} =
  let inStore: bool = name in symbolTable.store
  if inStore:
    return (symbolTable.store[name], true)

  if symbolTable.outer != nil:
    return symbolTable.outer.resolve(name)

  return (nil, false)
