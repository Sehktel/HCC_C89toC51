module Main (main) where

import Lexer (Token (..), lexer)
import Lexer_test (lexerABSpec, lexerAllTokensSpec, lexerTodoSpec, lexerMinimalSpec)
import Parser (Ast (..), parseTokens)
import Parser_test (parserTodoSpec)
import Preprocessor (preprocess)
import Preprocessor_test (preprocessorTodoSpec)
import AST_test (astTodoSpec)
import IR_test (irTodoSpec)
import Test.Hspec (describe, hspec, it, shouldBe)

main :: IO ()
main = hspec $ do
  lexerMinimalSpec
  lexerAllTokensSpec
  lexerABSpec
  lexerTodoSpec
  parserTodoSpec
  preprocessorTodoSpec
  astTodoSpec
  irTodoSpec
