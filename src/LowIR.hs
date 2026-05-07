module LowIR
  ( LowIR (..),
    lowerToLowIR,
  )
where

import MediumIR (MediumIR)

-- Низкоуровневое промежуточное представление (каркас).
data LowIR
  = LowIRRoot
  | LowIRTodo
  deriving (Eq, Show)

-- Понижение Medium IR в Low IR (заготовка).
lowerToLowIR :: MediumIR -> LowIR
lowerToLowIR _ = LowIRTodo
