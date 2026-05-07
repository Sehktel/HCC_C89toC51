module Main (main) where

import IR_test (irSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec irSpec
