module MediumIR_test (mediumIrSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)
import TestMatrix (recordPending)

mediumIrSpec :: Spec
mediumIrSpec =
  describe "Medium IR stage" $
    it "lowerToMediumIR: каркас теста готов" $ do
      recordPending "MediumIR" "lowerToMediumIR: каркас" "—" "TODO: HighIR -> MediumIR"
      pendingWith "TODO: добавить сценарии трансформации HighIR -> MediumIR"
