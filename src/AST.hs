module AST
  ( AST (..),
    fromParserAst,
  )
where

import qualified Parser as P

-- Представление абстрактно-семантического дерева (каркас).
data AST
  = ASTRoot
  | ASTTodo
  deriving (Eq, Show)

-- Преобразование синтаксического дерева парсера в AST (заготовка).
fromParserAst :: P.Ast -> AST
fromParserAst _ = ASTTodo
