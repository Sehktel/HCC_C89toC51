module Preprocessor (preprocess) where

import Data.Char (isSpace)

-- Простейший этап препроцессора: нормализуем пробелы и убираем пустые строки.
-- Здесь позже можно добавить обработку #define, #include, #if и т.д.
preprocess :: String -> String
preprocess =
  unlines
    . filter (not . null)
    . map trim
    . lines
    . replaceTrigraphs

-- Замена C89 trigraph-последовательностей до этапа лексического анализа.
-- Это соответствует ранним фазам трансляции C, где триграфы заменяются
-- на базовые символы ещё до токенизации.
replaceTrigraphs :: String -> String
replaceTrigraphs [] = []
replaceTrigraphs ('?' : '?' : '=' : rest) = '#' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '(' : rest) = '[' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '/' : rest) = '\\' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : ')' : rest) = ']' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '\'' : rest) = '^' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '<' : rest) = '{' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '!' : rest) = '|' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '>' : rest) = '}' : replaceTrigraphs rest
replaceTrigraphs ('?' : '?' : '-' : rest) = '~' : replaceTrigraphs rest
replaceTrigraphs (ch : rest) = ch : replaceTrigraphs rest

trim :: String -> String
trim = dropWhileEndSafe isSpace . dropWhile isSpace

dropWhileEndSafe :: (Char -> Bool) -> String -> String
dropWhileEndSafe p = reverse . dropWhile p . reverse
