{-# LANGUAGE OverloadedStrings #-}

-- | Минимальный IR для эталонов tests/src_c/*.ir (до появления полноценного IR-модуля).
module IrGolden
  ( Ir (..),
    toIr,
    renderIrGolden,
  )
where

import Parser (Ast (..), Expr (..))

data Ir
  = IrFunction String
  | IrReturnConst Int
  | IrUnknown
  deriving (Eq, Show)

toIr :: Ast -> [Ir]
toIr ast =
  case ast of
    AstProgram [AstFunctionDef fnName _ _ (AstCompound [AstReturn (Just (ExprLitInt value))])] ->
      [IrFunction fnName, IrReturnConst value]
    _ -> [IrUnknown]

renderIrGolden :: Ast -> String
renderIrGolden = show . toIr
