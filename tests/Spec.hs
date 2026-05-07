module Main (main) where

import Lexer_test (lexerABSpec, lexerAllTokensSpec, lexerFixtureSpec, lexerMinimalSpec, lexerTodoSpec)
import Parser_test (parserSpec)
import AST_test (astSpec)
import Preprocessor_test (preprocessorSpec)
import HighIR_test (highIrSpec)
import MediumIR_test (mediumIrSpec)
import LowIR_test (lowIrSpec)
import TreeDestroyer_test (treeDestroyerSpec)
import Peephole_test (peepholeSpec)
import SystemPipeline_test (systemPipelineSpec)
-- import Pipeline_test (pipelineSpec)
-- import IR_test (irSpec)


import Test.Hspec (hspec)

main :: IO ()
main = hspec $ do
  lexerMinimalSpec
  lexerAllTokensSpec
  lexerABSpec
  lexerTodoSpec
  lexerFixtureSpec
  parserSpec
  preprocessorSpec
  astSpec
  highIrSpec
  mediumIrSpec
  lowIrSpec
  treeDestroyerSpec
  peepholeSpec
  systemPipelineSpec
