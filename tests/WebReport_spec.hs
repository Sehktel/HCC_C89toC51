module Main (main) where

import AST_test (astSpec)
import HighIR_test (highIrSpec)
import IR_test (irSpec)
import Lexer_test (lexerABSpec, lexerAllTokensSpec, lexerFixtureSpec, lexerMinimalSpec, lexerTodoSpec)
import LowIR_test (lowIrSpec)
import ManifestRunner_test (manifestRunnerSpec)
import MediumIR_test (mediumIrSpec)
import Parser_test (parserSpec)
import Peephole_test (peepholeSpec)
import Preprocessor_test (preprocessorSpec)
import Test.Tasty (TestTree, defaultIngredients, defaultMainWithIngredients, testGroup)
import Test.Tasty.Hspec (testSpec)
import Test.Tasty.Runners.Html (htmlRunner)
import TreeDestroyer_test (treeDestroyerSpec)
import SystemPipeline_test (systemPipelineSpec)

main :: IO ()
main = do
  tree <- allTests
  defaultMainWithIngredients (htmlRunner : defaultIngredients) tree

allTests :: IO TestTree
allTests = do
  lexerMinimal <- testSpec "Lexer/minimal" lexerMinimalSpec
  lexerAllTokens <- testSpec "Lexer/all-tokens" lexerAllTokensSpec
  lexerAB <- testSpec "Lexer/ab" lexerABSpec
  lexerTodo <- testSpec "Lexer/todo" lexerTodoSpec
  lexerFixture <- testSpec "Lexer/fixture" lexerFixtureSpec
  parser <- testSpec "Parser" parserSpec
  preprocessor <- testSpec "Preprocessor" preprocessorSpec
  ast <- testSpec "AST" astSpec
  ir <- testSpec "IR" irSpec
  highIr <- testSpec "HighIR" highIrSpec
  mediumIr <- testSpec "MediumIR" mediumIrSpec
  lowIr <- testSpec "LowIR" lowIrSpec
  treeDestroyer <- testSpec "TreeDestroyer" treeDestroyerSpec
  peephole <- testSpec "Peephole" peepholeSpec
  systemPipeline <- testSpec "SystemPipeline" systemPipelineSpec
  manifestRunner <- testSpec "ManifestRunner" manifestRunnerSpec
  pure $
    testGroup
      "hcc-c89toc51 web report tests"
      [ lexerMinimal,
        lexerAllTokens,
        lexerAB,
        lexerTodo,
        lexerFixture,
        parser,
        preprocessor,
        ast,
        ir,
        highIr,
        mediumIr,
        lowIr,
        treeDestroyer,
        peephole,
        systemPipeline,
        manifestRunner
      ]
