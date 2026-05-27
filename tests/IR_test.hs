module IR_test (irSpec) where

import Control.Monad (forM_)
import IrGolden (Ir (..), renderIrGolden, toIr)
import Lexer (lexer)
import Logger (silentLogger)
import Parser (parseTokens)
import Preprocessor (preprocess)
import SrcCFixtures (discoverIrFixtures, goldenIrExt, srcCPreprocessConfig, trim)
import System.FilePath (replaceExtension)
import Test.Hspec (Spec, describe, it, runIO, shouldBe)
import TestMatrix (recordCompare, shouldBeRecorded)

irSpec :: Spec
irSpec = do
  describe "Pipeline AST -> IR" $ do
    it "строит минимальный IR из AST шаблона main/return" $ do
      let lg = silentLogger
          inp = "int main() { return 3; }"
      src <- preprocess srcCPreprocessConfig Nothing inp
      toks <- lexer lg src
      ast <- parseTokens lg toks
      let expected = [IrFunction "main", IrReturnConst 3]
      shouldBeRecorded "IR" "main/return 3" inp expected (toIr ast)

    it "на неподдерживаемой AST возвращает IrUnknown" $ do
      let lg = silentLogger
          inp = "int x;"
      toks <- lexer lg inp
      ast <- parseTokens lg toks
      shouldBeRecorded "IR" "int x; -> IrUnknown" inp [IrUnknown] (toIr ast)

  irFixtureSpec

irFixtureSpec :: Spec
irFixtureSpec = do
  fixtures <- runIO discoverIrFixtures
  let lg = silentLogger
  describe "IR fixtures (.ir)" $ do
    forM_ fixtures $ \cFile ->
      it ("строит IR для fixture " ++ cFile) $ do
        source <- readFile cFile
        expected <- readFile (replaceExtension cFile goldenIrExt)
        src <- preprocess srcCPreprocessConfig (Just cFile) source
        toks <- lexer lg src
        ast <- parseTokens lg toks
        let actual = renderIrGolden ast
            expTrim = trim expected
        recordCompare "IR fixture" cFile source expTrim actual
        actual `shouldBe` expTrim
