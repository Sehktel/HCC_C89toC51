module TreeDestroyer
  ( TDResult (..),
    destroyTree,
  )
where

import LowIR (LowIR)

-- Результат этапа разрушения дерева (Tree Destroyer, каркас).
data TDResult
  = TDLinearized
  | TDTodo
  deriving (Eq, Show)

-- Разрушение древовидной структуры в линейное представление (заготовка).
destroyTree :: LowIR -> TDResult
destroyTree _ = TDTodo
