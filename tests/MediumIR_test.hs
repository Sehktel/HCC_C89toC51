module MediumIR_test (mediumIrSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

mediumIrSpec :: Spec
mediumIrSpec =
  describe "Medium IR stage" $
    it "lowerToMediumIR: каркас теста готов" $
      pendingWith "TODO: добавить сценарии трансформации HighIR -> MediumIR"
