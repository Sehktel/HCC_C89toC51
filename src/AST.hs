{-# LANGUAGE LambdaCase #-}

-- | Семантическое AST — отдельный слой между синтаксисом и IR.
--
-- == Инварианты архитектуры (учебный компилятор) ==
--
-- * __Строгое разделение слоёв.__ 'Parser.Expr' / 'Parser.Ast' и 'Expr' / 'Stmt'
--   здесь — /разные/ типы; дублирование осознанное: ясность и воспроизводимость
--   важнее экономии строк.
-- * __'fromParserAst'__ — подъём и нормализация (desugaring, разбор деклараций,
--   таблица символов, const prop на уровне C). /Без/ полной типизации C89.
-- * __Типизация, проверка диапазонов, usual conversions__ — задачи IR
--   ('HighIR' и ниже), не этого модуля.
-- * __Пропуск AST и переход Parser → HighIR__ не рассматривается: деревья
--   похожи по форме, но отвечают на разные вопросы.
--
-- Парсер ('Parser.Ast') — «как записано?»; этот модуль — «какие сущности
-- программы?» (имена, декларации, scope, упрощённая форма операторов).
module AST
  ( -- * Корень
    AST (..),
    Program (..),
    ExternalDecl (..),
    FunctionDef (..),
    -- * Декларации (итерация 2: разбор из 'Token', без тип-check IR)
    Decl (..),
    DeclSpecifier (..),
    StorageClass (..),
    TypeQual (..),
    TypeSpec (..),
    C51MemoryClass (..),
    Declarator (..),
    DeclSuffix (..),
    -- * Операторы и выражения
    Stmt (..),
    Expr (..),
    BinOp (..),
    UnaryPre (..),
    SuffixOp (..),
    AssignOp (..),
    -- * Мост
    fromParserAst,
    parseDeclFromTokens,
  )
where

import Lexer (IntSuffix (..), Token (..))
import qualified Parser as P

-- | Результат семантического подъёма.
data AST
  = ASTProgram Program
  | ASTUnknown [Token]
  deriving (Eq, Show)

newtype Program = Program {programDecls :: [ExternalDecl]}
  deriving (Eq, Show)

data ExternalDecl
  = ExtFunction FunctionDef
  | ExtFunctionProto String
  | ExtDecl Decl
  | -- | Декларация не разобрана (struct, скобочный declarator, …).
    ExtDeclUnparsed [Token]
  deriving (Eq, Show)

data FunctionDef = FunctionDef
  { fnName :: String,
    fnDeclSpecs :: [DeclSpecifier],
    fnC51AttrTokens :: [Token],
    fnBody :: Stmt
  }
  deriving (Eq, Show)

-- | Декларация: спецификаторы + один или несколько declarator-ов.
data Decl = Decl
  { declSpecifiers :: [DeclSpecifier],
    declDeclarators :: [Declarator]
  }
  deriving (Eq, Show)

data DeclSpecifier
  = SpecStorage StorageClass
  | SpecTypeQual TypeQual
  | SpecType TypeSpec
  | SpecC51Memory C51MemoryClass
  deriving (Eq, Show)

data StorageClass
  = StorageAuto
  | StorageExtern
  | StorageRegister
  | StorageStatic
  | StorageTypedef
  deriving (Eq, Show)

data TypeQual
  = QualConst
  | QualVolatile
  deriving (Eq, Show)

-- | Базовые спецификаторы типа (структурная форма, не семантика IR).
data TypeSpec
  = TyVoid
  | TyChar
  | TyShort
  | TyInt
  | TyLong
  | TyFloat
  | TyDouble
  | TySigned
  | TyUnsigned
  | TyStruct
  | TyUnion
  | TyEnum
  | TySfr
  | TySfr16
  | TySbit
  | TySft
  | TyBit
  deriving (Eq, Show)

data C51MemoryClass
  = MemData
  | MemIdata
  | MemBdata
  | MemPdata
  | MemXdata
  | MemCode
  deriving (Eq, Show)

data Declarator = Declarator
  { dtorName :: String,
    dtorSuffixes :: [DeclSuffix],
    dtorInit :: Maybe Expr
  }
  deriving (Eq, Show)

data DeclSuffix
  = -- | @*@ перед именем (может повторяться).
    DtorPointer
  | -- | @[@ размер @]@; 'Nothing' — неизвестный размер @[]@.
    DtorArray (Maybe Expr)
  | -- | Скобки параметров прототипа (сырой фрагмент до разбора IR).
    DtorFunctionParams [Token]
  deriving (Eq, Show)

data Stmt
  = SCompound [Stmt]
  | SReturn (Maybe Expr)
  | SExpr (Maybe Expr)
  | SIf Expr Stmt (Maybe Stmt)
  | SWhile Expr Stmt
  | SFor (Maybe Expr) (Maybe Expr) (Maybe Expr) Stmt
  | SSwitch Expr Stmt
  | SCase Expr Stmt
  | SDefault Stmt
  | SDoWhile Stmt Expr
  | SBreak
  | SDecl Decl
  | SDeclUnparsed [Token]
  deriving (Eq, Show)

data Expr
  = ELitInt Int
  | ELitIntSuff Int IntSuffix
  | ELitChar Char
  | ELitString String
  | EVar String
  | EUnary UnaryPre Expr
  | EPostfix Expr [SuffixOp]
  | EBinary BinOp Expr Expr
  | ETernary Expr Expr Expr
  | EAssign AssignOp Expr Expr
  | EComma Expr Expr
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

-- * Разбор деклараций из потока токенов

-- | Разбор одной декларации (включая завершающий @;@).
--
-- При неудаче возвращает исходный список токенов без изменений.
parseDeclFromTokens :: [Token] -> Either [Token] Decl
parseDeclFromTokens raw =
  case parseDeclBody (stripTrailingSemicolon raw) of
    Left _ -> Left raw
    Right decl -> Right decl

stripTrailingSemicolon :: [Token] -> [Token]
stripTrailingSemicolon ts =
  case reverse ts of
    TokenSemicolon : rest -> reverse rest
    _ -> ts

parseDeclBody :: [Token] -> Either String Decl
parseDeclBody toks = do
  let (specToks, rest) = span isDeclSpecToken toks
  if null specToks
    then Left "expected declaration specifier"
    else do
      specs <- mapM tokenToDeclSpec specToks
      dtors <- parseDeclaratorList rest
      if null dtors
        then Left "expected declarator"
        else Right (Decl specs dtors)

parseDeclaratorList :: [Token] -> Either String [Declarator]
parseDeclaratorList [] = Left "empty declarator list"
parseDeclaratorList ts = do
  (dtor, rest) <- parseOneDeclarator ts
  case rest of
    [] -> Right [dtor]
    TokenComma : r -> (dtor :) <$> parseDeclaratorList r
    _ -> Left "unexpected tokens after declarator"

parseOneDeclarator :: [Token] -> Either String (Declarator, [Token])
parseOneDeclarator ts = do
  let (ptrToks, rest1) = span (== TokenMultiply) ts
      ptrSuffixes = replicate (length ptrToks) DtorPointer
  case rest1 of
    TokenIdentifier name : rest2 -> do
      (suffixes, rest3) <- parseDeclSuffixes rest2
      let allSuffixes = ptrSuffixes ++ suffixes
      case rest3 of
        TokenAssign : rest4 -> do
          (initSyn, rest5) <- P.parseExprTokensRest rest4
          pure (Declarator name allSuffixes (Just (fromParserExpr initSyn)), rest5)
        _ -> pure (Declarator name allSuffixes Nothing, rest3)
    TokenLeftParen : _ -> Left "parenthesized declarator not supported"
    _ -> Left "expected identifier in declarator"

-- | Постфиксные @[]@ и @()@ declarator-а.
parseDeclSuffixes :: [Token] -> Either String ([DeclSuffix], [Token])
parseDeclSuffixes ts = go [] ts
  where
    go acc = \case
      TokenLeftBracket : rest -> do
        (inner, after) <- collectBalancedBrackets rest
        sizeE <-
          if null inner
            then Right Nothing
            else Just <$> parseIndexSize inner
        go (DtorArray sizeE : acc) after
      TokenLeftParen : rest -> do
        (params, after) <- collectBalancedParens rest
        go (DtorFunctionParams params : acc) after
      rest -> Right (reverse acc, rest)

parseIndexSize :: [Token] -> Either String Expr
parseIndexSize inner =
  case P.parseExprTokensRest inner of
    Left _ -> Left "invalid array bound expression"
    Right (syn, rest)
      | null rest -> Right (fromParserExpr syn)
      | otherwise -> Left "trailing tokens in array bound"

collectBalancedBrackets :: [Token] -> Either String ([Token], [Token])
collectBalancedBrackets ts = go (1 :: Int) [] ts
  where
    go _ _ [] = Left "unterminated '[' in declarator"
    go 1 acc (TokenRightBracket : rest) = Right (reverse acc, rest)
    go d acc (TokenRightBracket : rest) = go (d - 1) (TokenRightBracket : acc) rest
    go d acc (TokenLeftBracket : rest) = go (d + 1) (TokenLeftBracket : acc) rest
    go d acc (t : rest) = go d (t : acc) rest

collectBalancedParens :: [Token] -> Either String ([Token], [Token])
collectBalancedParens ts = go (1 :: Int) [] ts
  where
    go _ _ [] = Left "unterminated '(' in declarator"
    go 1 acc (TokenRightParen : rest) = Right (reverse acc, rest)
    go d acc (TokenRightParen : rest) = go (d - 1) (TokenRightParen : acc) rest
    go d acc (TokenLeftParen : rest) = go (d + 1) (TokenLeftParen : acc) rest
    go d acc (t : rest) = go d (t : acc) rest

-- | Спецификатор декларации (зеркало 'Parser.isTypeToken').
isDeclSpecToken :: Token -> Bool
isDeclSpecToken = \case
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

tokenToDeclSpec :: Token -> Either String DeclSpecifier
tokenToDeclSpec = \case
  TokenAuto -> Right (SpecStorage StorageAuto)
  TokenRegister -> Right (SpecStorage StorageRegister)
  TokenStatic -> Right (SpecStorage StorageStatic)
  TokenExtern -> Right (SpecStorage StorageExtern)
  TokenTypedef -> Right (SpecStorage StorageTypedef)
  TokenConst -> Right (SpecTypeQual QualConst)
  TokenVolatile -> Right (SpecTypeQual QualVolatile)
  TokenVoid -> Right (SpecType TyVoid)
  TokenChar -> Right (SpecType TyChar)
  TokenShort -> Right (SpecType TyShort)
  TokenInt -> Right (SpecType TyInt)
  TokenLong -> Right (SpecType TyLong)
  TokenFloat -> Right (SpecType TyFloat)
  TokenDouble -> Right (SpecType TyDouble)
  TokenSigned -> Right (SpecType TySigned)
  TokenUnsigned -> Right (SpecType TyUnsigned)
  TokenStruct -> Right (SpecType TyStruct)
  TokenUnion -> Right (SpecType TyUnion)
  TokenEnum -> Right (SpecType TyEnum)
  TokenSfr -> Right (SpecType TySfr)
  TokenSfr16 -> Right (SpecType TySfr16)
  TokenSbit -> Right (SpecType TySbit)
  TokenSft -> Right (SpecType TySft)
  TokenBit -> Right (SpecType TyBit)
  TokenData -> Right (SpecC51Memory MemData)
  TokenIdata -> Right (SpecC51Memory MemIdata)
  TokenBdata -> Right (SpecC51Memory MemBdata)
  TokenPdata -> Right (SpecC51Memory MemPdata)
  TokenXdata -> Right (SpecC51Memory MemXdata)
  TokenCode -> Right (SpecC51Memory MemCode)
  TokenReentrant -> Right (SpecStorage StorageStatic)
  tok -> Left ("not a declaration specifier: " ++ show tok)

parseDeclSpecsOnly :: [Token] -> [DeclSpecifier]
parseDeclSpecsOnly toks =
  let (specToks, _) = span isDeclSpecToken toks
   in case mapM tokenToDeclSpec specToks of
        Left _ -> []
        Right specs -> specs

liftDecl :: [Token] -> Either [Token] Decl -> ExternalDecl
liftDecl raw = \case
  Left _ -> ExtDeclUnparsed raw
  Right decl -> ExtDecl decl

liftDeclStmt :: [Token] -> Either [Token] Decl -> Stmt
liftDeclStmt raw = \case
  Left _ -> SDeclUnparsed raw
  Right decl -> SDecl decl

-- * Подъём из Parser.Ast

fromParserAst :: P.Ast -> AST
fromParserAst ast =
  case ast of
    P.AstUnknown ts -> ASTUnknown ts
    P.AstProgram nodes -> ASTProgram (Program (map fromParserExternal nodes))
    P.AstFunctionDef {} -> ASTProgram (Program [fromParserExternal ast])
    P.AstFunction {} -> ASTProgram (Program [fromParserExternal ast])
    P.AstDeclaration {} -> ASTProgram (Program [fromParserExternal ast])
    _ -> ASTUnknown []

fromParserExternal :: P.Ast -> ExternalDecl
fromParserExternal = \case
  P.AstFunctionDef name specToks c51 body ->
    ExtFunction
      ( FunctionDef
          name
          (parseDeclSpecsOnly specToks)
          c51
          (fromParserStmt body)
      )
  P.AstFunction name -> ExtFunctionProto name
  P.AstDeclaration toks -> liftDecl toks (parseDeclFromTokens toks)
  other -> ExtDeclUnparsed (astToFallbackTokens other)

fromParserStmt :: P.Ast -> Stmt
fromParserStmt = \case
  P.AstCompound stmts -> SCompound (map fromParserStmt stmts)
  P.AstReturn me -> SReturn (fmap fromParserExpr me)
  P.AstExprStmt me -> SExpr (fmap fromParserExpr me)
  P.AstIf cond (P.AstCompound [thenBr, elseBr]) ->
    SIf (fromParserExpr cond) (fromParserStmt thenBr) (Just (fromParserStmt elseBr))
  P.AstIf cond thenBr ->
    SIf (fromParserExpr cond) (fromParserStmt thenBr) Nothing
  P.AstWhile cond body -> SWhile (fromParserExpr cond) (fromParserStmt body)
  P.AstFor forInit forCond forStep body ->
    SFor
      (fmap fromParserExpr forInit)
      (fmap fromParserExpr forCond)
      (fmap fromParserExpr forStep)
      (fromParserStmt body)
  P.AstSwitch disc body -> SSwitch (fromParserExpr disc) (fromParserStmt body)
  P.AstCase ce stmt -> SCase (fromParserExpr ce) (fromParserStmt stmt)
  P.AstDefault stmt -> SDefault (fromParserStmt stmt)
  P.AstDoWhile body cond -> SDoWhile (fromParserStmt body) (fromParserExpr cond)
  P.AstBreak -> SBreak
  P.AstDeclaration toks -> liftDeclStmt toks (parseDeclFromTokens toks)
  other -> SDeclUnparsed (astToFallbackTokens other)

fromParserExpr :: P.Expr -> Expr
fromParserExpr = \case
  P.ExprLitInt n -> ELitInt n
  P.ExprLitIntSuff n s -> ELitIntSuff n s
  P.ExprLitChar c -> ELitChar c
  P.ExprLitString s -> ELitString s
  P.ExprVar v -> EVar v
  P.ExprUnary op e -> EUnary (fromParserUnary op) (fromParserExpr e)
  P.ExprPostfix e ss -> EPostfix (fromParserExpr e) (map fromParserSuffix ss)
  P.ExprBinary op l r -> EBinary (fromParserBinOp op) (fromParserExpr l) (fromParserExpr r)
  P.ExprTernary c m e -> ETernary (fromParserExpr c) (fromParserExpr m) (fromParserExpr e)
  P.ExprAssign op l r -> EAssign (fromParserAssignOp op) (fromParserExpr l) (fromParserExpr r)
  P.ExprComma l r -> EComma (fromParserExpr l) (fromParserExpr r)

fromParserUnary :: P.UnaryPre -> UnaryPre
fromParserUnary = \case
  P.PrePlus -> PrePlus
  P.PreMinus -> PreMinus
  P.PreBang -> PreBang
  P.PreTilde -> PreTilde
  P.PreStar -> PreStar
  P.PreAmp -> PreAmp
  P.PreInc -> PreInc
  P.PreDec -> PreDec
  P.PreSizeof -> PreSizeof

fromParserSuffix :: P.SuffixOp -> SuffixOp
fromParserSuffix = \case
  P.SuffInc -> SuffInc
  P.SuffDec -> SuffDec
  P.SuffCall args -> SuffCall (map fromParserExpr args)
  P.SuffIndex idx -> SuffIndex (fromParserExpr idx)
  P.SuffMember fld -> SuffMember fld
  P.SuffArrow fld -> SuffArrow fld

fromParserBinOp :: P.BinOp -> BinOp
fromParserBinOp = \case
  P.OpMul -> OpMul
  P.OpDiv -> OpDiv
  P.OpMod -> OpMod
  P.OpAdd -> OpAdd
  P.OpSub -> OpSub
  P.OpShl -> OpShl
  P.OpShr -> OpShr
  P.OpLt -> OpLt
  P.OpGt -> OpGt
  P.OpLe -> OpLe
  P.OpGe -> OpGe
  P.OpEq -> OpEq
  P.OpNe -> OpNe
  P.OpBitAnd -> OpBitAnd
  P.OpBitXor -> OpBitXor
  P.OpBitOr -> OpBitOr
  P.OpAnd -> OpAnd
  P.OpOr -> OpOr

fromParserAssignOp :: P.AssignOp -> AssignOp
fromParserAssignOp = \case
  P.AAssign -> AAssign
  P.AAddAssign -> AAddAssign
  P.ASubAssign -> ASubAssign
  P.AMulAssign -> AMulAssign
  P.ADivAssign -> ADivAssign
  P.AModAssign -> AModAssign
  P.AShlAssign -> AShlAssign
  P.AShrAssign -> AShrAssign
  P.AAndAssign -> AAndAssign
  P.AXorAssign -> AXorAssign
  P.AOrAssign -> AOrAssign

astToFallbackTokens :: P.Ast -> [Token]
astToFallbackTokens _ = []
