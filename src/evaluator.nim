from ast import Node, NodeType
from obj import Obj, Env, newInteger


proc eval*(node: Node, env: Env): Obj # Forward declaration

proc evaluateProgram(node: Node, env: Env): Obj =
  var resultValue: Obj = nil
  for statement in node.statements:
    resultValue = eval(statement, env)
    echo statement.nodeType
  return resultValue

proc eval*(node: Node, env: Env): Obj =
  case node.nodeType:
    of NTProgram: evaluateProgram(node, env)
    of NTExpressionStatement: eval(node.expression, env)
    of NTIntegerLiteral: newInteger(intValue=node.intValue)
    else: nil
