-- | High IR — типизация, проверки и понижение после семантического AST.
--
-- Слой IR (не 'Parser', не 'AST'): usual arithmetic conversions,
-- согласованность типов, проверка диапазонов под целевую машину (8051/C51),
-- подготовка к basic blocks и temps. 'buildHighIR' принимает уже нормализованный
-- 'AST' без повторного разбора токенов.
module HighIR
  ( HighIR (..),
    buildHighIR,
  )
where

import AST (AST)

-- Высокоуровневое промежуточное представление (каркас).
data HighIR
  = HighIRRoot
  | HighIRTodo
  deriving (Eq, Show)

-- Построение High IR из AST (заготовка).
buildHighIR :: AST -> HighIR
buildHighIR _ = HighIRTodo
