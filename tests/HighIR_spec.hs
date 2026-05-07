module Main (main) where

import HighIR_test (highIrSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec highIrSpec
