module TreeDestroyer_test (treeDestroyerSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)
import TestMatrix (recordPending)

treeDestroyerSpec :: Spec
treeDestroyerSpec =
  describe "Tree Destroyer stage" $
    it "destroyTree: каркас теста готов" $ do
      recordPending "TreeDestroyer" "destroyTree: каркас" "—" "TODO: LowIR -> TDResult"
      pendingWith "TODO: добавить сценарии разрушения дерева LowIR -> TDResult"
