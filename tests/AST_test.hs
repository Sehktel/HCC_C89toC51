module AST_test (astTodoSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

astTodoSpec :: Spec
astTodoSpec =
  describe "AST TODO" $ do
    it "TODO: проверить корректность построения AST для операторов и выражений" $ do
      pendingWith "TODO: определить структуру AST и покрыть золотыми тестами."
