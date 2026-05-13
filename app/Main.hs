module Main (main) where

import Lexer (lexer)
import Parser (parseTokens)
import Preprocessor (PreprocessConfig (..), defaultPreprocessConfig, preprocess, stderrLoggerInfo)

main :: IO ()
main = do
  -- Минимальный демонстрационный вход для пайплайна C89 -> C51.
  let sourceCode = "int main() { return 0; }"
      pipelineLog = stderrLoggerInfo
      cfg = defaultPreprocessConfig {pcLogger = pipelineLog}
  preprocessedCode <- preprocess cfg Nothing sourceCode
  tokens <- lexer pipelineLog preprocessedCode
  ast <- parseTokens pipelineLog tokens
  putStrLn "=== PREPROCESSED ==="
  putStrLn preprocessedCode
  putStrLn "=== TOKENS ==="
  print tokens
  putStrLn "=== AST ==="
  print ast
