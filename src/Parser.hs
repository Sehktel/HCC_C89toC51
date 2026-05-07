module Parser (Ast (..), parseTokens) where

import Lexer (Token (..))

-- Текущее покрытие грамматики парсером (фактически реализованный поднабор):
-- 1) Единица трансляции:
--    - <translation-unit> ::= { <external-declaration> }*
-- 2) Внешние объявления:
--    - <function-definition> в форме:
--      <decl-specifier>+ <identifier> "(" ... ")" [<c51-func-attr>]* <compound-statement>
--      где <c51-func-attr> — это суффиксы Keil C51: interrupt / using с константным выражением
--      (выражение разбирается лишь на уровне потока токенов с балансом скобок).
--    - <declaration> (распознаётся и сохраняется как сырой список токенов; в т.ч. xdata/sfr/_at_).
-- 3) Составной оператор:
--    - <compound-statement> ::= "{" { <statement> }* "}"
-- 4) Операторы:
--    - <return-statement> (как `return;`, так и `return <expr>;`)
--    - <if-statement> с optional `else`
--    - <while-statement>
--    - <for-statement> c тремя секциями заголовка
--    - вложенный блок `{ ... }`
--    - <expression-statement> (`<expr>;`)
-- 5) Выражения:
--    - пока не строится полноценное дерево приоритетов;
--      выражение хранится как "сырой" список токенов в `AstExpr` / `AstReturnExpr`.
--
-- Важно: это намеренно прагматичный этап. Полное соответствие C89-грамматике
-- (включая declarator/initializer/expression precedence tree) пока не завершено.

-- AST пока остаётся компактным: покрываем ключевые синтаксические узлы
-- и сохраняем обратную совместимость с существующими тестами.
data Ast
  = AstProgram [Ast]
  | AstFunctionDef String [Token] [Token] Ast
  | AstFunction String
  | AstDeclaration [Token]
  | AstCompound [Ast]
  | AstReturn Int
  | AstReturnExpr [Token]
  | AstExpr [Token]
  | AstIf Ast (Maybe Ast)
  | AstWhile Ast
  | AstFor (Maybe Ast) (Maybe Ast) (Maybe Ast) Ast
  | AstUnknown [Token]
  deriving (Eq, Show)

type ParseResult a = Either String (a, [Token])

-- Точка входа:
-- - успешный полный разбор -> AstProgram ...
-- - любой частичный/ошибочный разбор -> AstUnknown с исходными токенами
parseTokens :: [Token] -> Ast
parseTokens tokens =
  case parseTranslationUnit tokens of
    Right (nodes, []) ->
      case nodes of
        [AstDeclaration _] -> AstUnknown tokens
        _ -> AstProgram nodes
    _ -> AstUnknown tokens

parseTranslationUnit :: [Token] -> ParseResult [Ast]
parseTranslationUnit [] = Right ([], [])
parseTranslationUnit ts = do
  (node, rest1) <- parseExternalDeclaration ts
  (more, rest2) <- parseTranslationUnit rest1
  Right (node : more, rest2)

parseExternalDeclaration :: [Token] -> ParseResult Ast
parseExternalDeclaration ts =
  case parseFunctionDefinition ts of
    Right res -> Right res
    Left _ ->
      case parseDeclaration ts of
        Right (decl, rest) -> Right (AstDeclaration decl, rest)
        Left err -> Left err

-- function-definition: decl-specifier+ identifier '(' ... ')' [interrupt|using const]* compound-stmt
-- Ограничение: декларатор — только простой идентификатор (без указателей на функцию и т.д.).
parseFunctionDefinition :: [Token] -> ParseResult Ast
parseFunctionDefinition ts = do
  (specs, rest1) <- parseAtLeastOneTypeToken ts
  case rest1 of
    TokenIdentifier fnName : TokenLeftParen : rest2 -> do
      rest3 <- consumeParenthesized rest2
      (c51Attrs, rest4) <- parseC51FuncAttrList rest3
      (body, rest5) <- parseCompoundStatement rest4
      -- Явный узел function-definition, чтобы не смешивать корень программы
      -- и структуру отдельной функции в одном AstProgram.
      Right (AstFunctionDef fnName specs c51Attrs body, rest5)
    _ -> Left "not a function definition"

-- | Суффиксы C51 после списка параметров: произвольная цепочка interrupt/using + const-выражение.
-- Константу не строим в дерево — сохраняем «сырые» токены (как и прочие выражения в этом парсере).
parseC51FuncAttrList :: [Token] -> ParseResult [Token]
parseC51FuncAttrList ts = go [] ts
  where
    go acc rest =
      case rest of
        TokenInterrupt : r ->
          case takeC51ConstExp r of
            Left err -> Left err
            Right (ce, r2)
              | null ce -> Left "expected constant expression after interrupt"
              | otherwise -> go (acc ++ (TokenInterrupt : ce)) r2
        TokenUsing : r ->
          case takeC51ConstExp r of
            Left err -> Left err
            Right (ce, r2)
              | null ce -> Left "expected constant expression after using"
              | otherwise -> go (acc ++ (TokenUsing : ce)) r2
        _ -> Right (acc, rest)

-- | Взять токены константного выражения до границы: следующий interrupt/using/{ при нулевой глубине
-- круглых и квадратных скобок. Так покрываются простые формы вроде @1@, @(1+2)@, @arr[3]@ без вложенных @{@.
takeC51ConstExp :: [Token] -> Either String ([Token], [Token])
takeC51ConstExp [] = Left "expected constant expression after interrupt/using"
takeC51ConstExp ts = go (0, 0) [] ts
  where
    go :: (Int, Int) -> [Token] -> [Token] -> Either String ([Token], [Token])
    go _ acc [] = Right (reverse acc, [])
    go (p, b) acc (tok : rest) =
      let (p', b') = case tok of
            TokenLeftParen -> (p + 1, b)
            TokenRightParen -> (max 0 (p - 1), b)
            TokenLeftBracket -> (p, b + 1)
            TokenRightBracket -> (p, max 0 (b - 1))
            _ -> (p, b)
          atBoundary =
            p == 0
              && b == 0
              && (tok == TokenLeftBrace || isC51AttrStarter tok)
       in if atBoundary
            then Right (reverse acc, tok : rest)
            else go (p', b') (tok : acc) rest

    isC51AttrStarter :: Token -> Bool
    isC51AttrStarter TokenInterrupt = True
    isC51AttrStarter TokenUsing = True
    isC51AttrStarter _ = False

parseDeclaration :: [Token] -> ParseResult [Token]
parseDeclaration ts = do
  (_, rest1) <- parseAtLeastOneTypeToken ts
  let (_, rest2) = break (== TokenSemicolon) rest1
  case rest2 of
    TokenSemicolon : rest3 -> Right (take (length ts - length rest3) ts, rest3)
    _ -> Left "unterminated declaration"

parseCompoundStatement :: [Token] -> ParseResult Ast
parseCompoundStatement (TokenLeftBrace : rest) = go [] rest
  where
    go acc (TokenRightBrace : tailTs) = Right (AstCompound (reverse acc), tailTs)
    go _ [] = Left "unterminated compound statement"
    go acc ts = do
      (stmt, restStmt) <- parseStatement ts
      go (stmt : acc) restStmt
parseCompoundStatement _ = Left "expected '{'"

parseStatement :: [Token] -> ParseResult Ast
parseStatement ts@(tok : _)
  | isTypeToken tok =
      case parseDeclaration ts of
        Right (decl, rest) -> Right (AstDeclaration decl, rest)
        Left err -> Left err
  | otherwise =
      case tok of
        TokenReturn -> parseReturnStatement ts
        TokenIf -> parseIfStatement ts
        TokenWhile -> parseWhileStatement ts
        TokenFor -> parseForStatement ts
        TokenLeftBrace -> parseCompoundStatement ts
        _ -> parseExpressionStatement ts
parseStatement [] = Left "unexpected EOF in statement"

parseReturnStatement :: [Token] -> ParseResult Ast
parseReturnStatement (TokenReturn : TokenSemicolon : rest) =
  Right (AstReturnExpr [], rest)
parseReturnStatement (TokenReturn : rest) =
  let (exprTokens, tailTs) = break (== TokenSemicolon) rest
   in case tailTs of
        TokenSemicolon : restAfter ->
          case exprTokens of
            [TokenNumber n] -> Right (AstReturn n, restAfter)
            _ -> Right (AstReturnExpr exprTokens, restAfter)
        _ -> Left "unterminated return statement"
parseReturnStatement _ = Left "expected return statement"

parseIfStatement :: [Token] -> ParseResult Ast
parseIfStatement (TokenIf : TokenLeftParen : rest) = do
  (condTokens, afterCond) <- collectBalancedParens [] 1 rest
  (thenBranch, rest1) <- parseStatement afterCond
  case rest1 of
    TokenElse : rest2 -> do
      (elseBranch, rest3) <- parseStatement rest2
      Right (AstIf (AstExpr condTokens) (Just (AstCompound [thenBranch, elseBranch])), rest3)
    _ -> Right (AstIf (AstExpr condTokens) (Just thenBranch), rest1)
parseIfStatement _ = Left "expected if statement"

parseWhileStatement :: [Token] -> ParseResult Ast
parseWhileStatement (TokenWhile : TokenLeftParen : rest) = do
  (condTokens, afterCond) <- collectBalancedParens [] 1 rest
  (body, rest1) <- parseStatement afterCond
  Right (AstWhile (AstCompound [AstExpr condTokens, body]), rest1)
parseWhileStatement _ = Left "expected while statement"

parseForStatement :: [Token] -> ParseResult Ast
parseForStatement (TokenFor : TokenLeftParen : rest) = do
  (initTokens, afterInit) <- takeUntilSemicolon rest
  (condTokens, afterCond) <- takeUntilSemicolon afterInit
  (stepTokens, afterStep) <- takeUntilRightParen afterCond
  (body, restAfterBody) <- parseStatement afterStep
  let initNode = toMaybeExpr initTokens
  let condNode = toMaybeExpr condTokens
  let stepNode = toMaybeExpr stepTokens
  Right (AstFor initNode condNode stepNode body, restAfterBody)
parseForStatement _ = Left "expected for statement"

parseExpressionStatement :: [Token] -> ParseResult Ast
parseExpressionStatement ts =
  let (exprTokens, rest) = break (== TokenSemicolon) ts
   in case rest of
        TokenSemicolon : restAfter -> Right (AstExpr exprTokens, restAfter)
        _ -> Left "unterminated expression statement"

parseAtLeastOneTypeToken :: [Token] -> ParseResult [Token]
parseAtLeastOneTypeToken ts =
  let (specs, rest) = span isTypeToken ts
   in if null specs
        then Left "expected declaration specifier"
        else Right (specs, rest)

consumeParenthesized :: [Token] -> Either String [Token]
consumeParenthesized ts = snd <$> collectBalancedParens [] 1 ts

collectBalancedParens :: [Token] -> Int -> [Token] -> Either String ([Token], [Token])
collectBalancedParens _ _ [] = Left "unterminated parenthesized group"
collectBalancedParens acc depth (tok : rest) =
  case tok of
    TokenLeftParen -> collectBalancedParens (tok : acc) (depth + 1) rest
    TokenRightParen
      | depth == 1 -> Right (reverse acc, rest)
      | otherwise -> collectBalancedParens (tok : acc) (depth - 1) rest
    _ -> collectBalancedParens (tok : acc) depth rest

takeUntilSemicolon :: [Token] -> Either String ([Token], [Token])
takeUntilSemicolon ts =
  let (part, rest) = break (== TokenSemicolon) ts
   in case rest of
        TokenSemicolon : tailTs -> Right (part, tailTs)
        _ -> Left "expected ';' in for header"

takeUntilRightParen :: [Token] -> Either String ([Token], [Token])
takeUntilRightParen ts =
  let (part, rest) = break (== TokenRightParen) ts
   in case rest of
        TokenRightParen : tailTs -> Right (part, tailTs)
        _ -> Left "expected ')' in for header"

toMaybeExpr :: [Token] -> Maybe Ast
toMaybeExpr [] = Nothing
toMaybeExpr tokens = Just (AstExpr tokens)

isTypeToken :: Token -> Bool
isTypeToken token =
  case token of
    TokenAuto -> True
    TokenRegister -> True
    TokenStatic -> True
    TokenExtern -> True
    TokenTypedef -> True
    TokenVoid -> True
    TokenChar -> True
    TokenShort -> True
    TokenInt -> True
    TokenLong -> True
    TokenFloat -> True
    TokenDouble -> True
    TokenSigned -> True
    TokenUnsigned -> True
    TokenStruct -> True
    TokenUnion -> True
    TokenEnum -> True
    TokenConst -> True
    TokenVolatile -> True
    TokenSfr -> True
    TokenSfr16 -> True
    TokenSbit -> True
    TokenSft -> True
    TokenBit -> True
    TokenData -> True
    TokenIdata -> True
    TokenBdata -> True
    TokenPdata -> True
    TokenXdata -> True
    TokenCode -> True
    TokenReentrant -> True
    _ -> False