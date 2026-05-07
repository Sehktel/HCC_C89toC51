module Main (main) where

import AST_test (astSpec)
import Lexer_test (lexerMinimalSpec)
import Parser_test (parserSpec)
import Preprocessor_test (preprocessorSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec $ do
  lexerMinimalSpec
  preprocessorSpec
  parserSpec
  astSpec
