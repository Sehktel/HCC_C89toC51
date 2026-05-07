module Main (main) where

import ManifestRunner_test (manifestRunnerSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec manifestRunnerSpec
