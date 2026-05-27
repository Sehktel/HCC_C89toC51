module HighIR_test (highIrSpec) where

import Control.Monad (forM_)
import SrcCFixtures (discoverHirFixtures)
import Test.Hspec (Spec, describe, it, pendingWith, runIO)
import TestMatrix (recordPending)

highIrSpec :: Spec
highIrSpec = do
  describe "High IR stage" $
    it "buildHighIR: каркас теста готов" $ do
      recordPending "HighIR" "buildHighIR: каркас" "—" "TODO: AST -> HighIR"
      pendingWith "TODO: добавить сценарии трансформации AST -> HighIR"

  hirFixtureSpec

hirFixtureSpec :: Spec
hirFixtureSpec = do
  fixtures <- runIO discoverHirFixtures
  describe "HighIR fixtures (.hir)" $ do
    forM_ fixtures $ \cFile ->
      it ("эталон HighIR " ++ cFile) $ do
        recordPending "HighIR fixture" cFile "—" "TODO: AST -> HighIR"
        pendingWith "TODO: трансформация AST -> HighIR ещё не реализована"
