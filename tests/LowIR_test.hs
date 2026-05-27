module LowIR_test (lowIrSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)
import TestMatrix (recordPending)

lowIrSpec :: Spec
lowIrSpec =
  describe "Low IR stage" $
    it "lowerToLowIR: каркас теста готов" $ do
      recordPending "LowIR" "lowerToLowIR: каркас" "—" "TODO: MediumIR -> LowIR"
      pendingWith "TODO: добавить сценарии трансформации MediumIR -> LowIR"
