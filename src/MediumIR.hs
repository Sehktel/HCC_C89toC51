module MediumIR
  ( MediumIR (..),
    lowerToMediumIR,
  )
where

import HighIR (HighIR)

-- Среднеуровневое промежуточное представление (каркас).
data MediumIR
  = MediumIRRoot
  | MediumIRTodo
  deriving (Eq, Show)

-- Понижение High IR в Medium IR (заготовка).
lowerToMediumIR :: HighIR -> MediumIR
lowerToMediumIR _ = MediumIRTodo
