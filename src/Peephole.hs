module Peephole
  ( PeepholeResult (..),
    peepholeOptimize,
  )
where

import TreeDestroyer (TDResult)

-- Результат точечной оптимизации (каркас).
data PeepholeResult
  = PeepholeOptimized
  | PeepholeTodo
  deriving (Eq, Show)

-- Применение peephole-оптимизаций к линейному коду (заготовка).
peepholeOptimize :: TDResult -> PeepholeResult
peepholeOptimize _ = PeepholeTodo
