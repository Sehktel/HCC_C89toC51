module Main (main) where

import Test.Hspec (hspec)
import TreeDestroyer_test (treeDestroyerSpec)

main :: IO ()
main = hspec treeDestroyerSpec
