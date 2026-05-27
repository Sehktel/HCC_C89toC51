module Peephole_test (peepholeSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)
import TestMatrix (recordPending)

peepholeSpec :: Spec
peepholeSpec =
  describe "Peephole stage" $
    it "peepholeOptimize: каркас теста готов" $ do
      recordPending "Peephole" "peepholeOptimize: каркас" "—" "TODO: TD -> Peephole"
      pendingWith "TODO: добавить сценарии точечной оптимизации TDResult -> PeepholeResult"
