module Main (main) where

import Lexer (Token, lexer)
import Parser (parseTokens)
import Preprocessor (preprocess)

main :: IO ()
main = do
  -- Минимальный демонстрационный вход для пайплайна C89 -> C51.
  let sourceCode = "int main() { return 0; }"
      preprocessedCode = preprocess sourceCode
      tokens = lexer preprocessedCode
      ast = parseTokens tokens
  putStrLn "=== PREPROCESSED ==="
  putStrLn preprocessedCode
  putStrLn "=== TOKENS ==="
  print tokens
  putStrLn "=== AST ==="
  print ast
