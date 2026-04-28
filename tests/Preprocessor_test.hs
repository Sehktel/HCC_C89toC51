module Preprocessor_test (preprocessorTodoSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

preprocessorTodoSpec :: Spec
preprocessorTodoSpec =
  describe "Preprocessor TODO" $ do
    it "TODO: добавить тесты на #define/#include и условную компиляцию" $ do
      pendingWith "TODO: реализовать полноценный препроцессор C и добавить кейсы."
