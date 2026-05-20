module Main (main) where

import Lexer (lexer)
import Logger (LogLevel (..), stderrLoggerFor)
import Parser (parseTokens)
import Preprocessor (PreprocessConfig (..), defaultPreprocessConfig, preprocess)

main :: IO ()
main = do
  -- Минимальный демонстрационный вход для пайплайна C89 -> C51.
  let sourceCode = "int main() { return 0; }"
      -- Глобальная болтливость тулчейна (позже — из конфига / флага CLI).
      globalLogMin = LogInfo
      pipelineLog = stderrLoggerFor globalLogMin
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
