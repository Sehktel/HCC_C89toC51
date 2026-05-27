module LowIR_test (lowIrSpec) where

import Control.Monad (forM_)
import SrcCFixtures (discoverLirFixtures)
import Test.Hspec (Spec, describe, it, pendingWith, runIO)
import TestMatrix (recordPending)

lowIrSpec :: Spec
lowIrSpec = do
  describe "Low IR stage" $
    it "lowerToLowIR: каркас теста готов" $ do
      recordPending "LowIR" "lowerToLowIR: каркас" "—" "TODO: MediumIR -> LowIR"
      pendingWith "TODO: добавить сценарии трансформации MediumIR -> LowIR"

  lirFixtureSpec

lirFixtureSpec :: Spec
lirFixtureSpec = do
  fixtures <- runIO discoverLirFixtures
  describe "LowIR fixtures (.lir)" $ do
    forM_ fixtures $ \cFile ->
      it ("эталон LowIR " ++ cFile) $ do
        recordPending "LowIR fixture" cFile "—" "TODO: MediumIR -> LowIR"
        pendingWith "TODO: трансформация MediumIR -> LowIR ещё не реализована"
