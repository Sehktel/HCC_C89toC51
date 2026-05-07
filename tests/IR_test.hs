module IR_test (irSpec) where

import Lexer (lexer)
import Parser (Ast (..), parseTokens)
import Preprocessor (preprocess)
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
    AstProgram [AstFunctionDef fnName _ _ (AstCompound [AstReturn value])] ->
      [IrFunction fnName, IrReturnConst value]
    _ -> [IrUnknown]

irSpec :: Spec
irSpec =
  describe "Pipeline AST -> IR" $ do
    it "строит минимальный IR из AST шаблона main/return" $ do
      let src = preprocess "int main() { return 3; }"
      toIr (parseTokens (lexer src))
        `shouldBe` [IrFunction "main", IrReturnConst 3]

    it "на неподдерживаемой AST возвращает IrUnknown" $ do
      toIr (parseTokens (lexer "int x;")) `shouldBe` [IrUnknown]
