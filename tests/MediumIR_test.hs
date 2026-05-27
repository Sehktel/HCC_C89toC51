module MediumIR_test (mediumIrSpec) where

import Control.Monad (forM_)
import SrcCFixtures (discoverMirFixtures)
import Test.Hspec (Spec, describe, it, pendingWith, runIO)
import TestMatrix (recordPending)

mediumIrSpec :: Spec
mediumIrSpec = do
  describe "Medium IR stage" $
    it "lowerToMediumIR: каркас теста готов" $ do
      recordPending "MediumIR" "lowerToMediumIR: каркас" "—" "TODO: HighIR -> MediumIR"
      pendingWith "TODO: добавить сценарии трансформации HighIR -> MediumIR"

  mirFixtureSpec

mirFixtureSpec :: Spec
mirFixtureSpec = do
  fixtures <- runIO discoverMirFixtures
  describe "MediumIR fixtures (.mir)" $ do
    forM_ fixtures $ \cFile ->
      it ("эталон MediumIR " ++ cFile) $ do
        recordPending "MediumIR fixture" cFile "—" "TODO: HighIR -> MediumIR"
        pendingWith "TODO: трансформация HighIR -> MediumIR ещё не реализована"
