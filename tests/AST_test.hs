module AST_test (astSpec) where

import Lexer (Token (..), lexer)
import Logger (silentLogger)
import Parser (Ast (..), Expr (..), parseTokens)
import Preprocessor (defaultPreprocessConfig, preprocess)
import Test.Hspec (Spec, describe, it, shouldBe)

astSpec :: Spec
astSpec =
  describe "Pipeline -> AST" $ do
    it "строит AST после этапа preprocess + lexer + parser" $ do
      let src = "  int main() {  \n return 7; \n}\n"
          lg = silentLogger
      normalized <- preprocess defaultPreprocessConfig Nothing src
      toks <- lexer lg normalized
      ast <- parseTokens lg toks
      ast
        `shouldBe` AstProgram
          [ AstFunctionDef
              "main"
              [TokenInt]
              []
              (AstCompound [AstReturn (Just (ExprLitInt 7))])
          ]

    it "на неподдерживаемом коде возвращает AstUnknown как промежуточный результат" $ do
      let src = "int x;"
          lg = silentLogger
      pp <- preprocess defaultPreprocessConfig Nothing src
      toks <- lexer lg pp
      ast <- parseTokens lg toks
      ast `shouldBe` AstUnknown [TokenInt, TokenIdentifier "x", TokenSemicolon]
