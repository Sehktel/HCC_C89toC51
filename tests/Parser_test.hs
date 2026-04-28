module Parser_test (parserTodoSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

parserTodoSpec :: Spec
parserTodoSpec =
  describe "Parser TODO" $ do
    it "TODO: добавить разбор if/else, do/while и блоков" $ do
      pendingWith "TODO: реализовать расширенный парсер и покрыть его тестами."
