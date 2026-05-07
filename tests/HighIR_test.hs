module HighIR_test (highIrSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

highIrSpec :: Spec
highIrSpec =
  describe "High IR stage" $
    it "buildHighIR: каркас теста готов" $
      pendingWith "TODO: добавить сценарии трансформации AST -> HighIR"
