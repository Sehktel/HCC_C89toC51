module IR_test (irSpec) where

import Lexer (lexer)
import Logger (silentLogger)
import Parser (Ast (..), Expr (..), parseTokens)
import Preprocessor (defaultPreprocessConfig, preprocess)
import Test.Hspec (Spec, describe, it, shouldBe)

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
      src <- preprocess defaultPreprocessConfig Nothing "int main() { return 3; }"
      toks <- lexer lg src
      ast <- parseTokens lg toks
      toIr ast `shouldBe` [IrFunction "main", IrReturnConst 3]

    it "на неподдерживаемой AST возвращает IrUnknown" $ do
      let lg = silentLogger
      toks <- lexer lg "int x;"
      ast <- parseTokens lg toks
      toIr ast `shouldBe` [IrUnknown]
