import tables
import hashes
import unittest
from ast import
  Node,
  NodeType,
  newIntegerLiteral,
  newProgram,
  newExpressionStatement,
  newPrefixExpression,
  newInfixExpression,
  newIndexOperation,
  newIfExpression,
  newBlockStatement,
  newReturnStatement,
  newAssignStatement,
  newIdentifier,
  newFuntionLiteral,
  newArrayLiteral,
  newDestructAssignStatement,
  newHashMapLiteral,
  newPipeLR,
  newPipeRL,
  newFNCompositionLR,
  newFNCompositionRL,
  newCaseExpression,
  toCode,
  hash
from ast_modify import modify
from obj import newEnv, Env
from token import newEmptyToken

type
  ExpectedNode = (Node, string)
  ExpectedNodes = seq[ExpectedNode]

suite "ast modify tests":
  test "modify":
    let one = proc(): Node =
      newIntegerLiteral(token=newEmptyToken(), intValue=1)
    let two = proc(): Node =
      newIntegerLiteral(token=newEmptyToken(), intValue=2)

    let tests: ExpectedNodes = @[
      (
        one(), "2"
      ),
      (
        newProgram(statements= @[
          newExpressionStatement(
            token=newEmptyToken(),
            expression=one()
          )
        ]),
        "2"
      ),
      (
        newInfixExpression(
          token=newEmptyToken(), infixLeft=one(), infixRight=two(), infixOperator="+"
        ),
        "(2 + 2)"
      ),
      (
        newInfixExpression(
          token=newEmptyToken(), infixLeft=two(), infixRight=one(), infixOperator="+"
        ),
        "(2 + 2)"
      ),
      (
        newPrefixExpression(
          token=newEmptyToken(), prefixRight=one(), prefixOperator="-"
        ),
        "(-2)"
      ),
      (
        newIndexOperation(
          token=newEmptyToken(), indexOpLeft=one(), indexOpIndex=one()
        ),
        "2[2]"
      ),
      (
        newIfExpression(
          token=newEmptyToken(),
          ifCondition=one(),
          ifConsequence=newBlockStatement(
            token=newEmptyToken(),
            blockStatements= @[
              one()
            ]
          ),
          ifAlternative=one()
        ),
        "if (2) 2 else 2 end"
      ),
      (
        newReturnStatement(token=newEmptyToken(), returnValue=one()),
        "return 2",
      ),
      (
        newAssignStatement(
          token=newEmptyToken(),
          assignName=newIdentifier(
            token=newEmptyToken(),
            identValue="myVar"
          ),
          assignValue=one()
        ),
        "let myVar = 2"
      ),
      (
        newFuntionLiteral(
          token=newEmptyToken(),
          functionBody=one(),
          functionParams= @[],
          functionName=newIdentifier(
            token=newEmptyToken(), identValue="fun"
          )
        ),
        "fn fun() 2 end"
      ),
      (
        newArrayLiteral(
          token=newEmptyToken(),
          arrayElements= @[
            one()
          ]
        ),
        "[2]"
      ),
      (
        newHashMapLiteral(
          token=newEmptyToken(),
          hashMapElements={
            newIdentifier(token=newEmptyToken(), identValue="myVar"): one(),
          }.toOrderedTable
        ),
        "{myVar: 2}"
      ),
      (
        newDestructAssignStatement(
          token=newEmptyToken(),
          destructAssignNamesAndIndexes= @[
            (
              newIdentifier(
                token=newEmptyToken(),
                identValue="myVar"
              ),
              one()
            )
          ],
          destructAssignValue=one()
        ),
        "let [myVar] = 2"
      ),
      (
        newPipeLR(
          token=newEmptyToken(),
          pipeLRLeft=one(),
          pipeLRRight=one(),
        ),
        "2 |> 2"
      ),
      (
        newPipeRL(
          token=newEmptyToken(),
          pipeRLLeft=one(),
          pipeRLRight=one(),
        ),
        "2 <| 2"
      ),
      (
        newFNCompositionLR(
          token=newEmptyToken(),
          fnCompositionLRLeft=one(),
          fnCompositionLRRight=one(),
        ),
        "2 >> 2"
      ),
      (
        newFNCompositionRL(
          token=newEmptyToken(),
          fnCompositionRLLeft=one(),
          fnCompositionRLRight=one(),
        ),
        "2 << 2"
      ),
      (
        newCaseExpression(
          token=newEmptyToken(),
          caseCondition=one(),
          casePatterns= @[
            (one(), one()),
          ]
        ),
        """case (2)
of 2 -> 2
end"""
      )
    ]

    let turnOneIntoTwo = proc(node: Node, env: var Env): Node =
      if node.nodeType != NTIntegerLiteral:
        return node

      if node.intValue != 1:
        return node

      node.intValue = 2
      return node

    for testPair in tests:
      var env: Env = newEnv()
      check modify(testPair[0], turnOneIntoTwo, env).toCode() == testPair[1]
