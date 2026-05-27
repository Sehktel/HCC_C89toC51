module IR_test (irSpec) where

import Lexer (lexer)
import Logger (silentLogger)
import Parser (Ast (..), Expr (..), parseTokens)
import Preprocessor (defaultPreprocessConfig, preprocess)
import Test.Hspec (Spec, describe, it)
import TestMatrix (shouldBeRecorded)

-- Локальное простое IR для промежуточной проверки конвейера.
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

irSpec :: Spec
irSpec =
  describe "Pipeline AST -> IR" $ do
    it "строит минимальный IR из AST шаблона main/return" $ do
      let lg = silentLogger
          inp = "int main() { return 3; }"
      src <- preprocess defaultPreprocessConfig Nothing inp
      toks <- lexer lg src
      ast <- parseTokens lg toks
      let expected = [IrFunction "main", IrReturnConst 3]
      shouldBeRecorded "IR" "main/return 3" inp expected (toIr ast)

    it "на неподдерживаемой AST возвращает IrUnknown" $ do
      let lg = silentLogger
          inp = "int x;"
      toks <- lexer lg inp
      ast <- parseTokens lg toks
      shouldBeRecorded "IR" "int x; -> IrUnknown" inp [IrUnknown] (toIr ast)
