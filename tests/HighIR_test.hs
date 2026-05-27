module HighIR_test (highIrSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)
import TestMatrix (recordPending)

highIrSpec :: Spec
highIrSpec =
  describe "High IR stage" $
    it "buildHighIR: каркас теста готов" $ do
      recordPending "HighIR" "buildHighIR: каркас" "—" "TODO: AST -> HighIR"
      pendingWith "TODO: добавить сценарии трансформации AST -> HighIR"
