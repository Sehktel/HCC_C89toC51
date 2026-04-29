module Parser_test (parserSpec) where

import Lexer (Token (..), lexer)
import Parser (Ast (..), parseTokens)
import Test.Hspec (Spec, describe, it, shouldBe)

parserSpec :: Spec
parserSpec = do
  describe "Parser.parseTokens" $ do
    it "строит AST для шаблона int main() { return 0; }" $ do
      parseTokens (lexer "int main() { return 0; }")
        `shouldBe` AstProgram [AstFunction "main", AstReturn 0]

    it "возвращает AstUnknown для неподдерживаемого паттерна" $ do
      parseTokens [TokenInt, TokenIdentifier "x"] `shouldBe` AstUnknown [TokenInt, TokenIdentifier "x"]
