module AST_test (astSpec) where

import Lexer (Token (..), lexer)
import Parser (Ast (..), Expr (..), parseTokens)
import Preprocessor (preprocess)
import Test.Hspec (Spec, describe, it, shouldBe)

astSpec :: Spec
astSpec =
  describe "Pipeline -> AST" $ do
    it "строит AST после этапа preprocess + lexer + parser" $ do
      let src = "  int main() {  \n return 7; \n}\n"
          normalized = preprocess src
      parseTokens (lexer normalized)
        `shouldBe` AstProgram
          [ AstFunctionDef
              "main"
              [TokenInt]
              []
              (AstCompound [AstReturn (Just (ExprLitInt 7))])
          ]

    it "на неподдерживаемом коде возвращает AstUnknown как промежуточный результат" $ do
      let src = "int x;"
      parseTokens (lexer (preprocess src))
        `shouldBe` AstUnknown [TokenInt, TokenIdentifier "x", TokenSemicolon]
