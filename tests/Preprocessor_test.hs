module Preprocessor_test (preprocessorSpec) where

import Preprocessor (preprocess)
import Test.Hspec (Spec, describe, it, shouldBe)

preprocessorSpec :: Spec
preprocessorSpec =
  describe "Preprocessor.preprocess" $ do
    it "убирает пустые строки и пробелы по краям" $ do
      preprocess "  int main() {  \n\n return 0; \n}\n"
        `shouldBe` "int main() {\nreturn 0;\n}\n"

    it "сохраняет порядок непустых строк" $ do
      preprocess "  a  \n  b\t\n\n c \n" `shouldBe` "a\nb\nc\n"

    it "заменяет trigraph-последовательности до лексера" $ do
      preprocess "??=define A 1\nint x ??( 0 ??) ;\n"
        `shouldBe` "#define A 1\nint x [ 0 ] ;\n"
