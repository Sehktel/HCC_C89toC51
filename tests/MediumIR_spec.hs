module Main (main) where

import MediumIR_test (mediumIrSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec mediumIrSpec
