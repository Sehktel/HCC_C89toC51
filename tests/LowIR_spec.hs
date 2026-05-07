module Main (main) where

import LowIR_test (lowIrSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec lowIrSpec
