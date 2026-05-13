module Preprocessor_test (preprocessorSpec) where

import Preprocessor (PreprocessConfig (..), defaultPreprocessConfig, preprocess)
import System.FilePath ((</>))
import Test.Hspec (Spec, describe, it, shouldBe)

preprocessorSpec :: Spec
preprocessorSpec =
  describe "Preprocessor.preprocess" $ do
    it "убирает пустые строки и пробелы по краям" $ do
      out <- preprocess defaultPreprocessConfig Nothing "  int main() {  \n\n return 0; \n}\n"
      out `shouldBe` "int main() {\nreturn 0;\n}\n"

    it "сохраняет порядок непустых строк" $ do
      out <- preprocess defaultPreprocessConfig Nothing "  a  \n  b\t\n\n c \n"
      out `shouldBe` "a\nb\nc\n"

    it "заменяет trigraph-последовательности и применяет #define" $ do
      out <- preprocess defaultPreprocessConfig Nothing "??=define A 1\nint x ??( 0 ??) ;\n"
      -- Директива исчезает; A в этой строке нет — остаётся только развёрнутая разметка скобок.
      out `shouldBe` "int x [ 0 ] ;\n"

    it "подставляет объектные макросы" $ do
      out <- preprocess defaultPreprocessConfig Nothing "#define N 42\nint y = N;\n"
      out `shouldBe` "int y = 42;\n"

    it "обрабатывает #ifdef / #else / #endif" $ do
      out <-
        preprocess defaultPreprocessConfig Nothing $
          "#define FOO\n"
            ++ "#ifdef FOO\n"
            ++ "int a = 1;\n"
            ++ "#else\n"
            ++ "int a = 2;\n"
            ++ "#endif\n"
      out `shouldBe` "int a = 1;\n"
      out2 <-
        preprocess defaultPreprocessConfig Nothing $
          "#ifdef FOO\n"
            ++ "int b = 1;\n"
            ++ "#else\n"
            ++ "int b = 2;\n"
            ++ "#endif\n"
      out2 `shouldBe` "int b = 2;\n"

    it "header guard: #ifndef не включает тело повторно при том же макросе" $ do
      out <-
        preprocess defaultPreprocessConfig Nothing $
          "#ifndef H_H\n"
            ++ "#define H_H\n"
            ++ "int z = 1;\n"
            ++ "#endif\n"
            ++ "#ifndef H_H\n"
            ++ "int z = 2;\n"
            ++ "#endif\n"
      out `shouldBe` "int z = 1;\n"

    it "подключает #include <> и \"\" (каталог угловых + каталог текущего файла)" $ do
      let cfg =
            defaultPreprocessConfig
              { pcAngleIncludeDirs = ["tests" </> "pp_include" </> "system"]
              }
          mainPath = "tests" </> "pp_include" </> "mainstub.c"
      out <-
        preprocess cfg (Just mainPath) $
          "#include <angle.h>\n"
            ++ "#include \"quoted.h\"\n"
            ++ "int v = ANGLE + QUOTED;\n"
      out `shouldBe` "int v = 40 + 2;\n"
