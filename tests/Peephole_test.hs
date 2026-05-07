module Peephole_test (peepholeSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

peepholeSpec :: Spec
peepholeSpec =
  describe "Peephole stage" $
    it "peepholeOptimize: каркас теста готов" $
      pendingWith "TODO: добавить сценарии точечной оптимизации TDResult -> PeepholeResult"
