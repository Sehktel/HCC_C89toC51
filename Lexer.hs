module Lexer (Token (..), lexC) where

import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)

data Token
  = TokKeyword String
  | TokIdentifier String
  | TokNumber Int
  | TokSymbol Char
  deriving (Eq, Show)

keywords :: [String]
keywords = ["int", "return", "void", "char", "if", "else", "while", "for"]

-- Минимальный лексер: разбирает идентификаторы, ключевые слова, числа и символы.
lexC :: String -> [Token]
lexC [] = []
lexC (c : cs)
  | isSpace c = lexC cs
  | isAlpha c || c == '_' =
      let (name, rest) = span (\x -> isAlphaNum x || x == '_') (c : cs)
       in classifyWord name : lexC rest
  | isDigit c =
      let (digits, rest) = span isDigit (c : cs)
       in TokNumber (read digits) : lexC rest
  | otherwise = TokSymbol c : lexC cs

classifyWord :: String -> Token
classifyWord word
  | word `elem` keywords = TokKeyword word
  | otherwise = TokIdentifier word
