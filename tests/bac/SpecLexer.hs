module Main (main) where

import Lexer_test (lexerABSpec, lexerAllTokensSpec, lexerFixtureSpec, lexerMinimalSpec, lexerTodoSpec)
import Test.Hspec (hspec)

main :: IO ()
main = hspec $ do
  lexerMinimalSpec
  lexerAllTokensSpec
  lexerABSpec
  lexerTodoSpec
  lexerFixtureSpec
