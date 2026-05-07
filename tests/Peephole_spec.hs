module Main (main) where

import Peephole_test (peepholeSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec peepholeSpec
