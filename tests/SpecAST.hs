module Main (main) where

import AST_test (astSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec astSpec
