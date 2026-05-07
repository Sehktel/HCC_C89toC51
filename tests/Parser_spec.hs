module Main (main) where

import Parser_test (parserSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec parserSpec
