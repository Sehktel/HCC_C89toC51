module TreeDestroyer_test (treeDestroyerSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

treeDestroyerSpec :: Spec
treeDestroyerSpec =
  describe "Tree Destroyer stage" $
    it "destroyTree: каркас теста готов" $
      pendingWith "TODO: добавить сценарии разрушения дерева LowIR -> TDResult"
