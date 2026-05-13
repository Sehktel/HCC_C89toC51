module Main (main) where

-- | На Windows по умолчанию текстовые файлы пишутся в кодировке локали (например CP1251),
-- а tasty-html помечает отчёт как UTF-8 — в браузере кириллица превращается в «кракозябры».
-- Явно фиксируем UTF-8 до любого вывода и записи отчёта.
import GHC.IO.Encoding (setFileSystemEncoding, setLocaleEncoding, utf8)
import System.IO (hSetEncoding, stderr, stdout)

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
import Test.Tasty (TestTree, defaultIngredients, defaultMainWithIngredients, localOption, testGroup)
import Test.Tasty.Hspec (TreatPendingAs (..), testSpec)
import Test.Tasty.Runners.Html (htmlRunner)
import TreeDestroyer_test (treeDestroyerSpec)
import SystemPipeline_test (systemPipelineSpec)

main :: IO ()
main = do
  setLocaleEncoding utf8
  setFileSystemEncoding utf8
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  tree <- allTests
  -- tasty-hspec по умолчанию мапит Hspec.pending/pendingWith в FAIL; для web-отчёта и cabal test all
  -- каркасные спеки должны оставаться «зелёными», иначе весь конвейер CI падает без реальной ошибки.
  defaultMainWithIngredients (htmlRunner : defaultIngredients) (localOption TreatPendingAsSuccess tree)

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
