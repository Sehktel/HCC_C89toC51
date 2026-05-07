module LowIR_test (lowIrSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

lowIrSpec :: Spec
lowIrSpec =
  describe "Low IR stage" $
    it "lowerToLowIR: каркас теста готов" $
      pendingWith "TODO: добавить сценарии трансформации MediumIR -> LowIR"
