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
