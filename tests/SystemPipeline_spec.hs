module Main (main) where

import SystemPipeline_test (systemPipelineSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec systemPipelineSpec
