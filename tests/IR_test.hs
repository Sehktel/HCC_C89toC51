module IR_test (irTodoSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

irTodoSpec :: Spec
irTodoSpec =
  describe "IR TODO" $ do
    it "TODO: добавить тесты трансляции AST -> IR" $ do
      pendingWith "TODO: определить промежуточное представление и его инварианты."
