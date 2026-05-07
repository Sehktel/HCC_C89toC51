module Main (main) where

import Preprocessor_test (preprocessorSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec preprocessorSpec
