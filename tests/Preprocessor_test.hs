module Preprocessor_test (preprocessorSpec) where

import Control.Monad (forM_)
import Preprocessor (PreprocessConfig (..), defaultPreprocessConfig, preprocess)
import SrcCFixtures (discoverPreprocessorFixtures, goldenPreprocessorExt, srcCPreprocessConfig, trim)
import System.FilePath ((</>), replaceExtension)
import Test.Hspec (Spec, describe, it, runIO, shouldBe)
import TestMatrix (recordCompare, shouldBeTextRecorded)

preprocessorSpec :: Spec
preprocessorSpec = do
  describe "Preprocessor.preprocess" $ do
    it "убирает пустые строки и пробелы по краям" $ do
      let inp = "  int main() {  \n\n return 0; \n}\n"
      shouldBeTextRecorded "Preprocessor" "убирает пустые строки и пробелы по краям" inp "int main() {\nreturn 0;\n}\n" (preprocess defaultPreprocessConfig Nothing inp)

    it "сохраняет порядок непустых строк" $ do
      let inp = "  a  \n  b\t\n\n c \n"
      shouldBeTextRecorded "Preprocessor" "сохраняет порядок непустых строк" inp "a\nb\nc\n" (preprocess defaultPreprocessConfig Nothing inp)

    it "заменяет trigraph-последовательности и применяет #define" $ do
      let inp = "??=define A 1\nint x ??( 0 ??) ;\n"
      shouldBeTextRecorded "Preprocessor" "trigraph + #define" inp "int x [ 0 ] ;\n" (preprocess defaultPreprocessConfig Nothing inp)

    it "подставляет объектные макросы" $ do
      let inp = "#define N 42\nint y = N;\n"
      shouldBeTextRecorded "Preprocessor" "подставляет объектные макросы" inp "int y = 42;\n" (preprocess defaultPreprocessConfig Nothing inp)

    it "обрабатывает #ifdef / #else / #endif" $ do
      let inp1 =
            "#define FOO\n"
              ++ "#ifdef FOO\n"
              ++ "int a = 1;\n"
              ++ "#else\n"
              ++ "int a = 2;\n"
              ++ "#endif\n"
      shouldBeTextRecorded "Preprocessor" "#ifdef FOO defined" inp1 "int a = 1;\n" (preprocess defaultPreprocessConfig Nothing inp1)
      let inp2 =
            "#ifdef FOO\n"
              ++ "int b = 1;\n"
              ++ "#else\n"
              ++ "int b = 2;\n"
              ++ "#endif\n"
      shouldBeTextRecorded "Preprocessor" "#ifdef FOO undefined" inp2 "int b = 2;\n" (preprocess defaultPreprocessConfig Nothing inp2)

    it "header guard: #ifndef не включает тело повторно при том же макросе" $ do
      let inp =
            "#ifndef H_H\n"
              ++ "#define H_H\n"
              ++ "int z = 1;\n"
              ++ "#endif\n"
              ++ "#ifndef H_H\n"
              ++ "int z = 2;\n"
              ++ "#endif\n"
      shouldBeTextRecorded "Preprocessor" "header guard #ifndef" inp "int z = 1;\n" (preprocess defaultPreprocessConfig Nothing inp)

    it "подключает #include <> и \"\" (каталог угловых + каталог текущего файла)" $ do
      let cfg =
            defaultPreprocessConfig
              { pcAngleIncludeDirs = ["tests" </> "pp_include" </> "system"]
              }
          mainPath = "tests" </> "pp_include" </> "mainstub.c"
          inp =
            "#include <angle.h>\n"
              ++ "#include \"quoted.h\"\n"
              ++ "int v = ANGLE + QUOTED;\n"
      shouldBeTextRecorded "Preprocessor" "#include <> и quoted" inp "int v = 40 + 2;\n" (preprocess cfg (Just mainPath) inp)

  preprocessorFixtureSpec

preprocessorFixtureSpec :: Spec
preprocessorFixtureSpec = do
  fixtures <- runIO discoverPreprocessorFixtures
  describe "Preprocessor fixtures (.pp)" $ do
    forM_ fixtures $ \cFile ->
      it ("препроцессирует fixture " ++ cFile) $ do
        source <- readFile cFile
        expected <- readFile (replaceExtension cFile goldenPreprocessorExt)
        actual <- preprocess srcCPreprocessConfig (Just cFile) source
        let expTrim = trim expected
        recordCompare "Preprocessor fixture" cFile source expTrim actual
        actual `shouldBe` expTrim
