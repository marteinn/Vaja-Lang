import unittest
from obj import
  Obj, ObjType, newInteger, newFloat, newStr, compareObj, TRUE, FALSE, NIL


suite "obj tests":
  test "obj comparisons":
    check compareObj(newStr("hello"), newInteger(1)) == false
    check compareObj(newInteger(1), newInteger(1)) == true
    check compareObj(newInteger(1), newInteger(2)) == false
    check compareObj(newFloat(1.0), newFloat(1.0)) == true
    check compareObj(newFloat(1.0), newFloat(2.0)) == false
    check compareObj(newStr("hello"), newStr("hello")) == true
    check compareObj(TRUE, TRUE) == true
    check compareObj(TRUE, FALSE) == false
    check compareObj(NIL, NIL) == true
