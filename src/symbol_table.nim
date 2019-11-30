import tables
import strformat

type
  SymbolScope* = string

const
  GLOBAL_SCOPE*: SymbolScope = "GLOBAL"

type
  Symbol* = ref object
    name*: string
    scope*: SymbolScope
    index*: int
  SymbolTable* = ref object
    store*: Table[string, Symbol]
    numDefinitions*: int

proc newSymbolTable*(): SymbolTable =
  let store: Table[string, Symbol] = initTable[string, Symbol]()
  return SymbolTable(store: store, numDefinitions: 0)

proc `$`*(symbol: Symbol): string =
  return fmt"name: {symbol.name}, scope: {symbol.scope}, index: {symbol.index}"

proc `==`*(symbolA: Symbol, symbolB: Symbol): bool =
  return (
    symbolA.name == symbolB.name and
    symbolA.scope == symbolB.scope and
    symbolA.index == symbolB.index
  )

method define*(symbolTable: var SymbolTable, name: string): Symbol {.base.} =
  let symbol: Symbol = Symbol(
    name: name,
    index: symbolTable.numDefinitions,
    scope: GLOBAL_SCOPE
  )

  symbolTable.store[name] = symbol
  symbolTable.numDefinitions = symbolTable.numDefinitions + 1

  return symbol

method resolve*(symbolTable: var SymbolTable, name: string): (Symbol, bool) {.base.} =
  if not (name in symbolTable.store):
    return (nil, false)

  let res = symbolTable.store[name]
  return (symbolTable.store[name], true)
