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

trim :: String -> String
trim = dropWhileEndSafe isSpace . dropWhile isSpace

dropWhileEndSafe :: (Char -> Bool) -> String -> String
dropWhileEndSafe p = reverse . dropWhile p . reverse
