{-# LANGUAGE LambdaCase #-}

-- | Синтаксический анализатор: подмножество C89 + C51-суффиксы функций.
--
-- === Выражения (@Expr@) и приоритеты
--
-- Иерархия задана __явно__ цепочкой функций: чем /выше/ уровень в таблице ниже,
-- тем /слабее/ связывание (оператор ближе к корню дерева). Реализация следует
-- обычной для C89 расстановке уровней; нормативная грамматика — в стандарте C89
-- (ANSI X3.159-1989; то же по сути, что ISO/IEC 9899:1990 — в литературе часто «C90»).
-- Ниже — инженерная карта «функция → операторы».
--
-- *Узкая ассоциативность:* большинство бинарных операторов — /левоассоциативны/
-- через 'binLeft'. Исключения: присваивание ('parseAssign') и условный @?:@
-- ('parseConditional') — /правоассоциативны/. Оператор запятой — левоассоциативен,
-- но запятая — самый слабый из перечисленных уровней выражения.
--
-- +---------------------------+----------------------------------------+----------------------------------+
-- | Слабее → сильнее (по     | Операторы (идея)                       | Входная точка в коде             |
-- | связыванию)               |                                        |                                  |
-- +===========================+========================================+==================================+
-- | 1. Запятая                | @,@                                    | 'parseComma'                     |
-- | 2. Присваивание           | @=@ @+=@ …                             | 'parseAssign'                    |
-- | 3. Условный               | @? :@                                  | 'parseConditional'               |
-- | 4. Логическое ИЛИ         | @\|\|@                                 | 'parseLogicalOr'                 |
-- | 5. Логическое И           | @&&@                                   | 'parseLogicalAnd'                |
-- | 6. Побитовое ИЛИ          | @\|@                                   | 'parseBitOr'                     |
-- | 7. Побитовое XOR          | @^@                                    | 'parseBitXor'                    |
-- | 8. Побитовое И            | @&@ (не @&&@)                          | 'parseBitAnd'                    |
-- | 9. Равенство              | @==@ @!=@                              | 'parseEquality'                  |
-- | 10. Отношение и сдвиг     | @<@ @>@ @<=@ @>=@ @<<@ @>>@           | 'parseRelational'                |
-- | 11. Аддитивные            | @+@ @-@ (бинарные)                     | 'parseAdditive'                  |
-- | 12. Мультипликативные     | @*@ @\/@ @%@                          | 'parseMultiplicative'            |
-- | 13. Унарные               | @+ - ! ~ * & ++ -- sizeof@ …           | 'parseUnary'                     |
-- | 14. Постфикс / первичный  | вызов, @[]@, @.@, @->@, литералы, @()@ | 'parsePostfix', 'parsePrimary'   |
-- +---------------------------+----------------------------------------+----------------------------------+
--
-- __Важно:__ уровень 10 (@parseRelational@) в одной функции совмещает цепочки
-- сдвига (@<<@, @>>@) и операторов отношения; порядок соответствует принятому
-- для C разделению «сдвиг слабее аддитивных, сильнее равенства» — см. код и
-- тесты @Parser_test@ на ожидаемую форму дерева.
--
-- === Точки входа выражения
--
-- * 'parseExprTokens' — полное выражение (включая запятую); используется в
--   скобках, аргументах, @return@, заголовках @for@ и т.д.
-- * 'parseConditionalExprTokens' — то же, но без уровня запятой: середина @case@
--   и тернарного оператора, где запятая должна относиться к внешнему @?:@.
--
-- === Не реализовано (подмножество языка)
--
-- Явные ограничения, чтобы не считать разбор полным C89 по выражениям:
-- приведение @(тип)@ как унарное, @sizeof(имя-типа)@ с полным разбором
-- @type-name@, составные литералы и прочие конструкции новее C89 — отсутствуют
-- или сведены к заглушкам. При расширении грамматики эту таблицу нужно обновить.
module Parser
  ( Ast (..),
    Expr (..),
    BinOp (..),
    UnaryPre (..),
    SuffixOp (..),
    AssignOp (..),
    parseTokens,
    parseTokensPure,
  )
where

import Lexer (IntSuffix (..), Token (..))
import Logger (LogLevel (..), Logger, logMsg)

-- | Дерево выражения.
--
-- По умолчанию бинарные узлы 'ExprBinary' — /левоассоциативны/ на своём уровне
-- (см. 'binLeft'). Исключения: 'ExprAssign' и 'ExprTernary' строятся с
-- правой рекурсией в 'parseAssign' и 'parseConditional'.
data Expr
  = ExprLitInt Int
  | ExprLitIntSuff Int IntSuffix
  | ExprLitChar Char
  | ExprLitString String
  | ExprVar String
  | ExprUnary UnaryPre Expr
  | ExprPostfix Expr [SuffixOp]
  | ExprBinary BinOp Expr Expr
  | ExprTernary Expr Expr Expr
  | ExprAssign AssignOp Expr Expr
  | ExprComma Expr Expr
  deriving (Eq, Show)

data UnaryPre
  = PrePlus
  | PreMinus
  | PreBang
  | PreTilde
  | PreStar
  | PreAmp
  | PreInc
  | PreDec
  | PreSizeof
  deriving (Eq, Show)

data SuffixOp
  = SuffInc
  | SuffDec
  | SuffCall [Expr]
  | SuffIndex Expr
  | SuffMember String
  | SuffArrow String
  deriving (Eq, Show)

data BinOp
  = OpMul
  | OpDiv
  | OpMod
  | OpAdd
  | OpSub
  | OpShl
  | OpShr
  | OpLt
  | OpGt
  | OpLe
  | OpGe
  | OpEq
  | OpNe
  | OpBitAnd
  | OpBitXor
  | OpBitOr
  | OpAnd
  | OpOr
  deriving (Eq, Show)

data AssignOp
  = AAssign
  | AAddAssign
  | ASubAssign
  | AMulAssign
  | ADivAssign
  | AModAssign
  | AShlAssign
  | AShrAssign
  | AAndAssign
  | AXorAssign
  | AOrAssign
  deriving (Eq, Show)

-- | Узлы операторов и деклараций (выражения — строго 'Expr').
data Ast
  = AstProgram [Ast]
  | AstFunctionDef String [Token] [Token] Ast
  | AstFunction String
  | AstDeclaration [Token]
  | AstCompound [Ast]
  | -- | @return;@ — 'Nothing'; @return expr;@ — 'Just'.
    AstReturn (Maybe Expr)
  | -- | Оператор-выражение или пустой @;@ ('Nothing').
    AstExprStmt (Maybe Expr)
  | AstIf Expr Ast
  | -- | Условие и тело; при @else@ тело — 'AstCompound' из двух веток.
    AstWhile Expr Ast
  | AstFor (Maybe Expr) (Maybe Expr) (Maybe Expr) Ast
  | AstSwitch Expr Ast
  | AstCase Expr Ast
  | AstDefault Ast
  | AstDoWhile Ast Expr
  | -- | @break;@ (выход из switch/цикла).
    AstBreak
  | AstUnknown [Token]
  deriving (Eq, Show)

type ParseResult a = Either String (a, [Token])

-- | Разбор без логирования (удобно в свойствах и отладке).
parseTokensPure :: [Token] -> Ast
parseTokensPure tokens =
  case parseTranslationUnit tokens of
    Right (nodes, []) ->
      case nodes of
        [AstDeclaration _] -> AstUnknown tokens
        _ -> AstProgram nodes
    _ -> AstUnknown tokens

-- | Разбор с логированием: сводка на @LogDebug@, @AstUnknown@ — предупреждение.
parseTokens :: Logger -> [Token] -> IO Ast
parseTokens lg tokens = do
  logMsg lg LogDebug $ "Parser: токенов на входе: " ++ show (length tokens)
  let ast = parseTokensPure tokens
  case ast of
    AstUnknown ts ->
      logMsg lg LogWarn $
        "Parser: единица трансляции не разобрана (AstUnknown), первые токены: "
          ++ take 200 (show ts)
    _ -> pure ()
  pure ast

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

parseFunctionDefinition :: [Token] -> ParseResult Ast
parseFunctionDefinition ts = do
  (specs, rest1) <- parseAtLeastOneTypeToken ts
  case rest1 of
    TokenIdentifier fnName : TokenLeftParen : rest2 -> do
      rest3 <- consumeParenthesized rest2
      (c51Attrs, rest4) <- parseC51FuncAttrList rest3
      (body, rest5) <- parseCompoundStatement rest4
      Right (AstFunctionDef fnName specs c51Attrs body, rest5)
    _ -> Left "not a function definition"

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

takeC51ConstExp :: [Token] -> Either String ([Token], [Token])
takeC51ConstExp [] = Left "expected constant expression after interrupt/using"
takeC51ConstExp ts = go ((0 :: Int), (0 :: Int)) [] ts
  where
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
    go acc ts' = do
      (stmt, restStmt) <- parseStatement ts'
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
        TokenDo -> parseDoWhileStatement ts
        TokenFor -> parseForStatement ts
        TokenSwitch -> parseSwitchStatement ts
        TokenCase -> parseCaseStatement ts
        TokenDefault -> parseDefaultStatement ts
        TokenBreak -> parseBreakStatement ts
        TokenLeftBrace -> parseCompoundStatement ts
        _ -> parseExpressionStatement ts
parseStatement [] = Left "unexpected EOF in statement"

parseBreakStatement :: [Token] -> ParseResult Ast
parseBreakStatement (TokenBreak : TokenSemicolon : rest) = Right (AstBreak, rest)
parseBreakStatement _ = Left "expected 'break;'"

parseReturnStatement :: [Token] -> ParseResult Ast
parseReturnStatement (TokenReturn : TokenSemicolon : rest) =
  Right (AstReturn Nothing, rest)
parseReturnStatement (TokenReturn : rest) =
  let (exprToks, tailTs) = break (== TokenSemicolon) rest
   in case tailTs of
        TokenSemicolon : restAfter ->
          if null exprToks
            then Left "empty return expression"
            else do
              expr <- parseExprTokens exprToks
              Right (AstReturn (Just expr), restAfter)
        _ -> Left "unterminated return statement"
parseReturnStatement _ = Left "expected return statement"

parseIfStatement :: [Token] -> ParseResult Ast
parseIfStatement (TokenIf : TokenLeftParen : rest) = do
  (condToks, afterCond) <- collectBalancedParens [] 1 rest
  cond <- parseExprTokens condToks
  (thenBranch, rest1) <- parseStatement afterCond
  case rest1 of
    TokenElse : rest2 -> do
      (elseBranch, rest3) <- parseStatement rest2
      Right (AstIf cond (AstCompound [thenBranch, elseBranch]), rest3)
    _ -> Right (AstIf cond thenBranch, rest1)
parseIfStatement _ = Left "expected if statement"

parseWhileStatement :: [Token] -> ParseResult Ast
parseWhileStatement (TokenWhile : TokenLeftParen : rest) = do
  (condToks, afterCond) <- collectBalancedParens [] 1 rest
  cond <- parseExprTokens condToks
  (body, rest1) <- parseStatement afterCond
  Right (AstWhile cond body, rest1)
parseWhileStatement _ = Left "expected while statement"

parseSwitchStatement :: [Token] -> ParseResult Ast
parseSwitchStatement (TokenSwitch : TokenLeftParen : rest) = do
  (condToks, afterCond) <- collectBalancedParens [] 1 rest
  disc <- parseExprTokens condToks
  (body, rest1) <- parseStatement afterCond
  Right (AstSwitch disc body, rest1)
parseSwitchStatement _ = Left "expected switch statement"

-- | Константное выражение в @case@: граница «:» с учётом вложенного «?:».
parseCaseStatement :: [Token] -> ParseResult Ast
parseCaseStatement (TokenCase : rest) =
  case splitAtTernaryColon rest of
    Left err -> Left err
    Right (ceToks, TokenColon : rest2)
      | null ceToks -> Left "empty case expression"
      | otherwise -> do
          ce <- parseConditionalExprTokens ceToks
          (stmt, rest3) <- parseAfterSwitchLabel rest2
          Right (AstCase ce stmt, rest3)
    _ -> Left "expected ':' after case expression"
parseCaseStatement _ = Left "expected case label"

parseDefaultStatement :: [Token] -> ParseResult Ast
parseDefaultStatement (TokenDefault : rest) =
  case rest of
    TokenColon : rest2 -> do
      (stmt, rest3) <- parseAfterSwitchLabel rest2
      Right (AstDefault stmt, rest3)
    _ -> Left "expected ':' after default"
parseDefaultStatement _ = Left "expected default label"

parseAfterSwitchLabel :: [Token] -> ParseResult Ast
parseAfterSwitchLabel [] = Left "expected statement after switch label"
parseAfterSwitchLabel ts'@(TokenCase : _) = parseCaseStatement ts'
parseAfterSwitchLabel ts'@(TokenDefault : _) = parseDefaultStatement ts'
parseAfterSwitchLabel ts' = parseStatement ts'

parseDoWhileStatement :: [Token] -> ParseResult Ast
parseDoWhileStatement (TokenDo : rest) = do
  (body, restAfterBody) <- parseStatement rest
  case restAfterBody of
    TokenWhile : TokenLeftParen : r2 -> do
      (condToks, afterCond) <- collectBalancedParens [] 1 r2
      cond <- parseExprTokens condToks
      case afterCond of
        TokenSemicolon : r3 -> Right (AstDoWhile body cond, r3)
        _ -> Left "expected ';' after do-while condition"
    _ -> Left "expected 'while' after do body"
parseDoWhileStatement _ = Left "expected do statement"

parseForStatement :: [Token] -> ParseResult Ast
parseForStatement (TokenFor : TokenLeftParen : rest) = do
  (initToks, afterInit) <- takeUntilSemicolon rest
  (condToks, afterCond) <- takeUntilSemicolon afterInit
  (stepToks, afterStep) <- takeUntilRightParen afterCond
  (body, restAfterBody) <- parseStatement afterStep
  initE <- parseOptionalExprTokens initToks
  condE <- parseOptionalExprTokens condToks
  stepE <- parseOptionalExprTokens stepToks
  Right (AstFor initE condE stepE body, restAfterBody)
parseForStatement _ = Left "expected for statement"

parseExpressionStatement :: [Token] -> ParseResult Ast
parseExpressionStatement ts =
  let (exprToks, rest) = break (== TokenSemicolon) ts
   in case rest of
        TokenSemicolon : restAfter ->
          if null exprToks
            then Right (AstExprStmt Nothing, restAfter)
            else do
              expr <- parseExprTokens exprToks
              Right (AstExprStmt (Just expr), restAfter)
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

-- * Разбор выражений
--
-- Порядок вызовов и приоритеты — в Haddock модуля (таблица уровней). Здесь —
-- только локальные детали реализации.

-- | Первая «:», завершающая фрагмент при вложенных «?:» (середина тернарного или @case@).
splitAtTernaryColon :: [Token] -> Either String ([Token], [Token])
splitAtTernaryColon ts = go (0 :: Int) [] ts
  where
    go _ _ [] = Left "expected ':'"
    go q acc (TokenColon : rest)
      | q == 0 = Right (reverse acc, TokenColon : rest)
      | otherwise = go (q - 1) (TokenColon : acc) rest
    go q acc (TokenQuestion : rest) = go (q + 1) (TokenQuestion : acc) rest
    go q acc (t : rest) = go q (t : acc) rest

-- | Полное выражение: самый слабый уровень — запятая ('parseComma').
parseExprTokens :: [Token] -> Either String Expr
parseExprTokens toks = do
  (e, rest) <- parseComma toks
  if null rest then Right e else Left "trailing tokens in expression"

-- | Выражение без уровня запятой (середина @?:@, выражение в @case@ до @:@).
parseConditionalExprTokens :: [Token] -> Either String Expr
parseConditionalExprTokens toks = do
  (e, rest) <- parseConditional toks
  if null rest then Right e else Left "trailing tokens in case expression"

parseOptionalExprTokens :: [Token] -> Either String (Maybe Expr)
parseOptionalExprTokens [] = Right Nothing
parseOptionalExprTokens toks = Just <$> parseExprTokens toks

-- | Оператор запятой: левоассоциативен; операнды — цепочки присваивания.
parseComma :: [Token] -> ParseResult Expr
parseComma ts = do
  (lhs, r1) <- parseAssign ts
  case r1 of
    TokenComma : r2 -> do
      (rhs, r3) <- parseComma r2
      Right (ExprComma lhs rhs, r3)
    _ -> Right (lhs, r1)

-- | Присваивание: правая ассоциативность (@a = b = c@ → @a = (b = c)@).
parseAssign :: [Token] -> ParseResult Expr
parseAssign ts = do
  (lhs, r1) <- parseConditional ts
  case assignOpFromToken r1 of
    Just (op, r2) -> do
      (rhs, r3) <- parseAssign r2
      Right (ExprAssign op lhs rhs, r3)
    Nothing -> Right (lhs, r1)

assignOpFromToken :: [Token] -> Maybe (AssignOp, [Token])
assignOpFromToken = \case
  TokenAssign : r -> Just (AAssign, r)
  TokenPlusAssign : r -> Just (AAddAssign, r)
  TokenMinusAssign : r -> Just (ASubAssign, r)
  TokenMultiplyEqual : r -> Just (AMulAssign, r)
  TokenDivideEqual : r -> Just (ADivAssign, r)
  TokenPercentEqual : r -> Just (AModAssign, r)
  TokenLessLessEqual : r -> Just (AShlAssign, r)
  TokenGreaterGreaterEqual : r -> Just (AShrAssign, r)
  TokenAmpersandEqual : r -> Just (AAndAssign, r)
  TokenCaretEqual : r -> Just (AXorAssign, r)
  TokenPipeEqual : r -> Just (AOrAssign, r)
  _ -> Nothing

-- | Условный @?:@: правая ассоциативность; ветка «иначе» снова 'parseConditional'.
parseConditional :: [Token] -> ParseResult Expr
parseConditional ts = do
  (lhs, r1) <- parseLogicalOr ts
  case r1 of
    TokenQuestion : r2 -> do
      case splitAtTernaryColon r2 of
        Left err -> Left err
        Right (midToks, TokenColon : r4)
          | null midToks -> Left "empty middle of conditional"
          | otherwise -> do
              mid <- parseExprTokens midToks
              (rhs, r5) <- parseConditional r4
              Right (ExprTernary lhs mid rhs, r5)
        _ -> Left "malformed conditional"
    _ -> Right (lhs, r1)

-- | Левоассоциативная цепочка одного бинарного оператора @op@ над подвыражениями @sub@.
binLeft ::
  ([Token] -> ParseResult Expr) ->
  BinOp ->
  ([Token] -> Maybe [Token]) ->
  [Token] ->
  ParseResult Expr
binLeft sub op chop ts = do
  (first, r) <- sub ts
  go first r
  where
    go lhs rest =
      case chop rest of
        Just r2 -> do
          (rhs, r3) <- sub r2
          go (ExprBinary op lhs rhs) r3
        Nothing -> Right (lhs, rest)

-- | @||@; операнды — уровень логического И.
parseLogicalOr :: [Token] -> ParseResult Expr
parseLogicalOr = binLeft parseLogicalAnd OpOr chop
  where
    chop (TokenPipePipe : r) = Just r
    chop _ = Nothing

-- | @&&@; операнды — побитовое ИЛИ.
parseLogicalAnd :: [Token] -> ParseResult Expr
parseLogicalAnd = binLeft parseBitOr OpAnd chop
  where
    chop (TokenAmpersandAmpersand : r) = Just r
    chop _ = Nothing

-- | Побитовое @|@ (не @||@); операнды — XOR.
parseBitOr :: [Token] -> ParseResult Expr
parseBitOr = binLeft parseBitXor OpBitOr chop
  where
    chop (TokenPipe : TokenPipe : _) = Nothing
    chop (TokenPipe : r) = Just r
    chop _ = Nothing

-- | Побитовое @^@; операнды — побитовое И.
parseBitXor :: [Token] -> ParseResult Expr
parseBitXor = binLeft parseBitAnd OpBitXor chop
  where
    chop (TokenCaret : TokenAssign : _) = Nothing
    chop (TokenCaret : r) = Just r
    chop _ = Nothing

-- | Побитовое @&@ (не @&&@); операнды — равенство.
parseBitAnd :: [Token] -> ParseResult Expr
parseBitAnd = binLeft parseEquality OpBitAnd chop
  where
    chop (TokenAmpersand : TokenAmpersand : _) = Nothing
    chop (TokenAmpersand : TokenAssign : _) = Nothing
    chop (TokenAmpersand : r) = Just r
    chop _ = Nothing

-- | Отношения (@<@ @>@ @<=@ @>=@) и сдвиги (@<<@ @>>@) относительно аддитивного уровня.
-- Реализация объединена в одной функции; порядок см. в теле и в тестах приоритета.
parseRelational :: [Token] -> ParseResult Expr
parseRelational ts = goShift ts >>= goRel
  where
    goRel (lhs, r) = case r of
      TokenLeftAngle : TokenAssign : _ -> Right (lhs, r)
      TokenLeftAngle : r2 -> do (rhs, r3) <- goShift r2; goRel (ExprBinary OpLt lhs rhs, r3)
      TokenRightAngle : TokenAssign : _ -> Right (lhs, r)
      TokenRightAngle : r2 -> do (rhs, r3) <- goShift r2; goRel (ExprBinary OpGt lhs rhs, r3)
      TokenLessEqual : r2 -> do (rhs, r3) <- goShift r2; goRel (ExprBinary OpLe lhs rhs, r3)
      TokenGreaterEqual : r2 -> do (rhs, r3) <- goShift r2; goRel (ExprBinary OpGe lhs rhs, r3)
      _ -> Right (lhs, r)
    goShift ts' = binLeft parseAdditive OpShl chopShl ts' >>= uncurry goShr
    chopShl (TokenLessLessEqual : _) = Nothing
    chopShl (TokenLessLess : r) = Just r
    chopShl _ = Nothing
    goShr lhs r@(TokenGreaterGreaterEqual : _) = Right (lhs, r)
    goShr lhs (TokenGreaterGreater : r2) = do
      (rhs, r3) <- parseAdditive r2
      goShr (ExprBinary OpShr lhs rhs) r3
    goShr lhs r = Right (lhs, r)

-- | @+@ и бинарный @-@ (унарный @-@ — в 'parseUnary').
parseAdditive :: [Token] -> ParseResult Expr
parseAdditive ts = binLeft parseMultiplicative OpAdd chopPlus ts >>= goMinus
  where
    chopPlus (TokenPlus : TokenPlus : _) = Nothing
    chopPlus (TokenPlus : TokenAssign : _) = Nothing
    chopPlus (TokenPlus : r) = Just r
    chopPlus _ = Nothing
    goMinus (lhs, r) = case r of
      TokenMinus : TokenMinus : _ -> Right (lhs, r)
      TokenMinus : TokenAssign : _ -> Right (lhs, r)
      TokenMinus : TokenRightAngle : _ -> Right (lhs, r)
      TokenMinus : r2 -> do
        (rhs, r3) <- parseMultiplicative r2
        goMinus (ExprBinary OpSub lhs rhs, r3)
      _ -> Right (lhs, r)

-- | @*@ @\/@ @%@; звёздочка различается с разыменованием по контексту ('chopStar').
parseMultiplicative :: [Token] -> ParseResult Expr
parseMultiplicative ts = binLeft parseUnary OpMul chopStar ts >>= goDivMod
  where
    chopStar (TokenMultiply : TokenAssign : _) = Nothing
    chopStar (TokenMultiply : r) = Just r
    chopStar _ = Nothing
    goDivMod (lhs, r) = case r of
      TokenDivide : TokenAssign : _ -> Right (lhs, r)
      TokenDivide : r2 -> do
        (rhs, r3) <- parseUnary r2
        goDivMod (ExprBinary OpDiv lhs rhs, r3)
      TokenPercent : TokenAssign : _ -> Right (lhs, r)
      TokenPercent : r2 -> do
        (rhs, r3) <- parseUnary r2
        goDivMod (ExprBinary OpMod lhs rhs, r3)
      _ -> Right (lhs, r)

-- | Префиксные операторы; правая ассоциативность цепочки унарных.
parseUnary :: [Token] -> ParseResult Expr
parseUnary ts =
  case ts of
    TokenPlus : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PrePlus e, r2)
    TokenMinus : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PreMinus e, r2)
    TokenBang : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PreBang e, r2)
    TokenTilde : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PreTilde e, r2)
    TokenMultiply : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PreStar e, r2)
    TokenAmpersand : TokenAmpersand : _ -> parsePostfix ts
    TokenAmpersand : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PreAmp e, r2)
    TokenPlusPlus : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PreInc e, r2)
    TokenMinusMinus : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PreDec e, r2)
    TokenSizeof : r -> do (e, r2) <- parseUnary r; Right (ExprUnary PreSizeof e, r2)
    _ -> parsePostfix ts

-- | Постфиксная цепочка после атома ('parsePostfixChain').
parsePostfix :: [Token] -> ParseResult Expr
parsePostfix ts = do
  (atom, r) <- parsePrimary ts
  parsePostfixChain atom r

-- | Атом: литерал, идентификатор, скобочное подвыражение ('parseExprTokens' внутри).
parsePrimary :: [Token] -> ParseResult Expr
parsePrimary ts =
  case ts of
    TokenNumber n : r -> Right (ExprLitInt n, r)
    TokenNumberWithSuffix n s : r -> Right (ExprLitIntSuff n s, r)
    TokenCharLiteral c : r -> Right (ExprLitChar c, r)
    TokenStringLiteral s : r -> Right (ExprLitString s, r)
    TokenIdentifier name : r -> Right (ExprVar name, r)
    TokenLeftParen : r -> do
      (inner, afterParen) <- collectBalancedParens [] 1 r
      e <- parseExprTokens inner
      Right (e, afterParen)
    _ -> Left "expected primary expression"

addSuffix :: Expr -> SuffixOp -> Expr
addSuffix (ExprPostfix e ss) op = ExprPostfix e (ss ++ [op])
addSuffix e op = ExprPostfix e [op]

collectBalancedBrackets :: [Token] -> Either String ([Token], [Token])
collectBalancedBrackets ts = go (1 :: Int) [] ts
  where
    go _ _ [] = Left "unterminated '['"
    go 1 acc (TokenRightBracket : rest) = Right (reverse acc, rest)
    go d acc (TokenRightBracket : rest) = go (d - 1) (TokenRightBracket : acc) rest
    go d acc (TokenLeftBracket : rest) = go (d + 1) (TokenLeftBracket : acc) rest
    go d acc (t : rest) = go d (t : acc) rest

parseArgList :: [Token] -> Either String ([Expr], [Token])
parseArgList ts =
  case ts of
    TokenRightParen : rest -> Right ([], rest)
    _ -> do
      (e1, r1) <- parseComma ts
      case r1 of
        TokenComma : r2 -> do
          (es, r3) <- parseArgList r2
          Right (e1 : es, r3)
        TokenRightParen : rest -> Right ([e1], rest)
        _ -> Left "expected ',' or ')' in argument list"

parsePostfixChain :: Expr -> [Token] -> ParseResult Expr
parsePostfixChain e ts =
  case ts of
    TokenPlusPlus : r -> parsePostfixChain (addSuffix e SuffInc) r
    TokenMinusMinus : r -> parsePostfixChain (addSuffix e SuffDec) r
    TokenLeftParen : r -> do
      (args, afterArgs) <- parseArgList r
      case afterArgs of
        TokenRightParen : r2 -> parsePostfixChain (addSuffix e (SuffCall args)) r2
        _ -> Left "expected ')' after call"
    TokenLeftBracket : r -> do
      (inner, afterIdx) <- collectBalancedBrackets r
      idx <- parseExprTokens inner
      parsePostfixChain (addSuffix e (SuffIndex idx)) afterIdx
    TokenDot : TokenIdentifier fld : r -> parsePostfixChain (addSuffix e (SuffMember fld)) r
    TokenMinus : TokenRightAngle : TokenIdentifier fld : r ->
      parsePostfixChain (addSuffix e (SuffArrow fld)) r
    _ -> Right (e, ts)

-- | @==@ @!=@; операнды — уровень 'parseRelational' (цепочка левоассоциативна).
parseEquality :: [Token] -> ParseResult Expr
parseEquality ts = do
  (first, r) <- parseRelational ts
  go first r
  where
    go lhs (TokenEqual : r2) = do
      (rhs, r3) <- parseRelational r2
      go (ExprBinary OpEq lhs rhs) r3
    go lhs (TokenBangEqual : r2) = do
      (rhs, r3) <- parseRelational r2
      go (ExprBinary OpNe lhs rhs) r3
    go lhs r = Right (lhs, r)