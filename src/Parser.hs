module Parser (Ast (..), parseTokens) where

import Lexer (Token (..))

data Ast
  = AstProgram [Ast]
  | AstFunction String
  | AstReturn Int
  | AstUnknown [Token]
  deriving (Eq, Show)

-- Упрощённый парсер для шаблона: int <name>() { return <num>; }
-- В реальном проекте лучше перейти на parser combinators или Happy/Alex.
parseTokens :: [Token] -> Ast
parseTokens tokens =
  case tokens of
    [ TokenInt,
      TokenIdentifier fnName,
      TokenLeftParen,
      TokenRightParen,
      TokenLeftBrace,
      TokenReturn,
      TokenNumber n,
      TokenSemicolon,
      TokenRightBrace
      ] -> AstProgram [AstFunction fnName, AstReturn n]
    _ -> AstUnknown tokens
