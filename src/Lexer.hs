{-|
Модуль лексического анализа для подмножества C89/C51.

Модуль переводит входной текст в последовательность токенов:

- ключевые слова;
- операторы и разделители;
- идентификаторы;
- числовые, строковые и символьные литералы;
- токены ошибок лексического анализа.
-}
module Lexer (IntSuffix (..), Token (..), lexer, lexerPure) where

import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)
import Data.Foldable (traverse_)
import Logger (LogLevel (..), Logger, logMsg, logMsgLazy)

-- | Токены лексического анализа.
data Token
   = TokenOne -- | Зарезервированное слово @one@ (служебный токен Frontend-а).
  | TokenOf -- | Зарезервированное слово @of@ (служебный токен Frontend-а).
  | TokenAuto -- | Ключевое слово C @auto@.
  | TokenDouble -- | Ключевое слово C @double@.
  | TokenInt -- | Ключевое слово C @int@.
  | TokenStruct -- | Ключевое слово C @struct@.
  | TokenBreak -- | Ключевое слово C @break@.
  | TokenElse -- | Ключевое слово C @else@.
  | TokenLong -- | Ключевое слово C @long@.
  | TokenSwitch -- | Ключевое слово C @switch@.
  | TokenCase -- | Ключевое слово C @case@.
  | TokenEnum -- | Ключевое слово C @enum@.
  | TokenRegister -- | Ключевое слово C @register@.
  | TokenTypedef -- | Ключевое слово C @typedef@.
  | TokenChar -- | Ключевое слово C @char@.
  | TokenExtern -- | Ключевое слово C @extern@.
  | TokenReturn -- | Ключевое слово C @return@.
  | TokenUnion -- | Ключевое слово C @union@.
  | TokenConst -- | Ключевое слово C @const@.
  | TokenFloat -- | Ключевое слово C @float@.
  | TokenShort -- | Ключевое слово C @short@.
  | TokenUnsigned -- | Ключевое слово C @unsigned@.
  | TokenContinue -- | Ключевое слово C @continue@.
  | TokenFor    -- | Ключевое слово C @for@.
  | TokenSigned -- | Ключевое слово C @signed@.
  | TokenVoid -- | Ключевое слово C @void@.
  | TokenDefault -- | Ключевое слово C @default@.
  | TokenGoto -- | Ключевое слово C @goto@.
  | TokenSizeof -- | Ключевое слово C @sizeof@.
  | TokenVolatile -- | Ключевое слово C @volatile@.
  | TokenDo -- | Ключевое слово C @do@.
  | TokenIf -- | Ключевое слово C @if@.
  | TokenStatic -- | Ключевое слово C @static@.
  | TokenWhile -- | Ключевое слово C @while@.
  | TokenSfr -- | Ключевое слово C51 архитектуры @sfr@.
  | TokenSfr16 -- | Ключевое слово C51 архитектуры @sfr16@.
  | TokenSbit -- | Ключевое слово C51 архитектуры @sbit@.
  | TokenSft -- | Ключевое слово C51 архитектуры @sft@.
  | TokenBit -- | Ключевое слово C51 архитектуры @bit@.
  | TokenData -- | Ключевое слово C51 архитектуры @data@.
  | TokenIdata -- | Ключевое слово C51 архитектуры @idata@.
  | TokenBdata -- | Ключевое слово C51 архитектуры @bdata@.
  | TokenPdata -- | Ключевое слово C51 архитектуры @pdata@.
  | TokenXdata -- | Ключевое слово C51 архитектуры @xdata@.
  | TokenCode -- | Ключевое слово C51 архитектуры @code@.
  | TokenInterrupt -- | Ключевое слово C51 архитектуры @interrupt@.
  | TokenUsing -- | Ключевое слово C51 архитектуры @using@.
  | TokenReentrant -- | Ключевое слово C51 архитектуры @reentrant@.
  | TokenAt -- "_at_"
  | TokenAssign -- | Оператор присваивания @=@.
  | TokenEqual -- "=="
  | TokenPlus -- | Оператор сложения @+@.
  | TokenPlusAssign -- | Оператор сложения с присваиванием @+=@.
  | TokenMinus -- | Оператор вычитания @-@.
  | TokenMinusAssign -- | Оператор вычитания с присваиванием @-=@.
  | TokenMultiply -- | Оператор умножения @*@.
  | TokenDivide -- | Оператор деления @/@.
  | TokenSemicolon -- | Оператор semicolon @;@.
  | TokenComma -- | Оператор comma @,@.
  | TokenDot -- | Оператор dot @.@.
  | TokenColon -- | Оператор colon @:@.
  | TokenQuestion -- | Оператор question @?@.
  | TokenBang -- | Оператор bang (not) @!@.
  | TokenHash -- | Оператор hash @#@.
  | TokenPercent -- | Оператор percent (modulo) @%@.
  | TokenAmpersand -- | Оператор ampersand (and) @&@.
  | TokenPipe -- | Оператор pipe (or) @|@.
  | TokenTilde -- | Оператор tilde (not) @~@.
  | TokenCaret -- | Оператор caret (xor) @^@.
  | TokenBackslash -- | Оператор backslash (escape) @\@.
  | TokenLeftParen -- | Оператор left parenthesis (круглая открывающаяся скобка) @(@.
  | TokenRightParen -- | Оператор right parenthesis (круглая закрывающаяся скобка) @)@.
  | TokenLeftBrace -- | Оператор left brace (фигурная открывающаяся скобка) @{@.
  | TokenRightBrace -- | Оператор right brace (фигурная закрывающаяся скобка) @}@.
  | TokenLeftBracket -- | Оператор left bracket (квадратная открывающаяся скобка) @[@.
  | TokenRightBracket -- | Оператор right bracket (квадратная закрывающаяся скобка) @]@.
  | TokenLeftAngle -- | Оператор left angle (угловая открывающаяся скобка) @<@.
  | TokenRightAngle -- | Оператор right angle (угловая закрывающаяся скобка) @>@.
  | TokenPipePipe -- | Оператор pipe pipe (логическое или) @||@.
  | TokenAmpersandAmpersand -- | Оператор ampersand ampersand (логическое и) @&&@.
  | TokenPlusPlus -- | Оператор plus plus (инкремент) @++@.
  | TokenMinusMinus -- | Оператор minus minus (декремент) @--@.
  | TokenLessLess -- | Оператор less less (сдвиг влево) @<<@.
  | TokenGreaterGreater -- | Оператор greater greater (сдвиг вправо) @>>@.
  | TokenLessLessEqual -- | Оператор less less equal (сдвиг влево с присваиванием) @<<=@.
  | TokenGreaterGreaterEqual -- | Оператор greater greater equal (сдвиг вправо с присваиванием) @>>=@.
  | TokenBangEqual -- | Оператор bang equal (не равно) @!=@.
  | TokenGreaterEqual -- | Оператор greater equal (больше или равно) @>=@.
  | TokenLessEqual -- | Оператор less equal (меньше или равно) @<=@.
  | TokenAmpersandEqual -- | Оператор ampersand equal (и с присваиванием) @&=@.
  | TokenPipeEqual -- | Оператор pipe equal (или с присваиванием) @|=@.
  | TokenCaretEqual -- | Оператор caret equal (xor с присваиванием) @^=@.
  | TokenPercentEqual -- | Оператор percent equal (modulo с присваиванием) @%=@.
  | TokenMultiplyEqual -- | Оператор multiply equal (умножение с присваиванием) @*=@.
  | TokenDivideEqual -- | Оператор divide equal (деление с присваиванием) @/=@.
  | TokenIdentifier String -- идентификатор
  | TokenNumber Int -- число
  | TokenNumberWithSuffix Int IntSuffix -- целое число с суффиксом C
  | TokenStringLiteral String -- строковый литерал
  | TokenCharLiteral Char -- символьный литерал
  | TokenLexError String -- ошибка лексического анализа
  | TokenSymbol Char -- символ
  deriving (Eq, Show)

-- | Суффикс целочисленного литерала в стиле C89.
data IntSuffix
  = SufU
  | SufL
  | SufUL
  deriving (Eq, Show)

-- Псевдонимы типов для улучшения читаемости сигнатур лексера.
type InputRest = String
type LexStepResult = (Token, InputRest)
type SuffixError = (String, InputRest)
type SuffixParseResult = (Maybe IntSuffix, InputRest)

-- Явные токены для ключевых слов, которые критичны для синтаксиса.
keywordToToken :: String -> Maybe Token
keywordToToken "one" = Just TokenOne
keywordToToken "of" = Just TokenOf
keywordToToken "auto" = Just TokenAuto
keywordToToken "double" = Just TokenDouble
keywordToToken "if" = Just TokenIf
keywordToToken "struct" = Just TokenStruct
keywordToToken "break" = Just TokenBreak
keywordToToken "else" = Just TokenElse
keywordToToken "long" = Just TokenLong
keywordToToken "switch" = Just TokenSwitch
keywordToToken "case" = Just TokenCase
keywordToToken "enum" = Just TokenEnum
keywordToToken "register" = Just TokenRegister
keywordToToken "typedef" = Just TokenTypedef
keywordToToken "char" = Just TokenChar
keywordToToken "extern" = Just TokenExtern
keywordToToken "do" = Just TokenDo
keywordToToken "while" = Just TokenWhile
keywordToToken "int" = Just TokenInt
keywordToToken "return" = Just TokenReturn
keywordToToken "union" = Just TokenUnion
keywordToToken "const" = Just TokenConst
keywordToToken "float" = Just TokenFloat
keywordToToken "short" = Just TokenShort
keywordToToken "unsigned" = Just TokenUnsigned
keywordToToken "continue" = Just TokenContinue
keywordToToken "for" = Just TokenFor
keywordToToken "signed" = Just TokenSigned
keywordToToken "void" = Just TokenVoid
keywordToToken "default" = Just TokenDefault
keywordToToken "goto" = Just TokenGoto
keywordToToken "sizeof" = Just TokenSizeof
keywordToToken "volatile" = Just TokenVolatile
keywordToToken "static" = Just TokenStatic
keywordToToken "sfr" = Just TokenSfr
keywordToToken "sfr16" = Just TokenSfr16
keywordToToken "sbit" = Just TokenSbit
keywordToToken "sft" = Just TokenSft
keywordToToken "bit" = Just TokenBit
keywordToToken "data" = Just TokenData
keywordToToken "idata" = Just TokenIdata
keywordToToken "bdata" = Just TokenBdata
keywordToToken "pdata" = Just TokenPdata
keywordToToken "xdata" = Just TokenXdata
keywordToToken "code" = Just TokenCode
keywordToToken "interrupt" = Just TokenInterrupt
keywordToToken "using" = Just TokenUsing
keywordToToken "reentrant" = Just TokenReentrant
keywordToToken "_at_" = Just TokenAt
keywordToToken _ = Nothing



-- | Чистый лексический разбор (без логирования); для пайплайна предпочтительнее 'lexer'.
lexerPure :: String -> [Token]
lexerPure [] = []
lexerPure (c : cs)
  | isSpace c = lexerPure cs
  | c == '"' =
      let (stringToken, rest) = lexStringLiteral cs
       in stringToken : lexerPure rest
  | c == '\'' =
      let (charToken, rest) = lexCharLiteral cs
       in charToken : lexerPure rest
  | isAlpha c || c == '_' =
      let (name, rest) = span (\x -> isAlphaNum x || x == '_') (c : cs)
       in classifyWord name : lexerPure rest
  | isDigit c =
      let (numberToken, rest) = lexNumber (c : cs)
       in numberToken : lexerPure rest
  | otherwise =
      let (token, rest) = lexOperator c cs
       in token : lexerPure rest

-- | Лексер с логированием: сводка на @LogDebug@, каждый @TokenLexError@ — на @LogWarn@.
lexer :: Logger -> String -> IO [Token]
lexer lg input = do
  let toks = lexerPure input
  logMsgLazy lg LogDebug $ \_ -> "Lexer: токенов: " ++ show (length toks)
  traverse_ logLexErr toks
  pure toks
  where
    logLexErr (TokenLexError msg) = logMsg lg LogWarn $ "Lexer: " ++ msg
    logLexErr _ = pure ()

-- Разбор чисел: поддержка десятичных, шестнадцатеричных (0x) и восьмеричных (0...).
lexNumber :: String -> LexStepResult
lexNumber ('0' : 'x' : rest) = lexHexNumber rest
lexNumber ('0' : 'X' : rest) = lexHexNumber rest
lexNumber ('0' : rest@(d : _))
  | isDigit d =
      let (numberDigits, tailRest) = span isDigit rest
          literal = '0' : numberDigits
       in if hasInvalidOctalDigit numberDigits
            then (TokenLexError ("Invalid octal literal: " ++ literal), tailRest)
            else attachIntegerSuffix (readOctal literal) tailRest
lexNumber ('0' : rest) = attachIntegerSuffix 0 rest
lexNumber input =
  let (digits, rest) = span isDigit input
   in attachIntegerSuffix (read digits) rest

lexHexNumber :: String -> LexStepResult
lexHexNumber input =
  let (hexDigits, rest) = span isHexDigit input
   in if null hexDigits
        then (TokenLexError "Invalid hexadecimal literal: 0x", input)
        else attachIntegerSuffix (readHex hexDigits) rest

isHexDigit :: Char -> Bool
isHexDigit ch = isDigit ch || lowerHex >= 'a' && lowerHex <= 'f'
  where
    lowerHex
      | ch >= 'A' && ch <= 'F' = toEnum (fromEnum ch + 32)
      | otherwise = ch

readHex :: String -> Int
readHex = foldl (\acc ch -> acc * 16 + hexDigitValue ch) 0

hexDigitValue :: Char -> Int
hexDigitValue ch
  | isDigit ch = fromEnum ch - fromEnum '0'
  | upper >= 'A' && upper <= 'F' = fromEnum upper - fromEnum 'A' + 10
  | otherwise = 0
  where
    upper
      | ch >= 'a' && ch <= 'f' = toEnum (fromEnum ch - 32)
      | otherwise = ch

readOctal :: String -> Int
readOctal = foldl step 0
  where
    step acc ch
      | ch >= '0' && ch <= '7' = acc * 8 + (fromEnum ch - fromEnum '0')
      | otherwise = acc

hasInvalidOctalDigit :: String -> Bool
hasInvalidOctalDigit = any (\ch -> ch == '8' || ch == '9')

-- Суффиксы целочисленных литералов C89: U, L, UL, LU (в любом регистре).
attachIntegerSuffix :: Int -> InputRest -> LexStepResult
attachIntegerSuffix value rest =
  case parseIntegerSuffix rest of
    Left (err, tailRest) -> (TokenLexError err, tailRest)
    Right (Nothing, tailRest) -> (TokenNumber value, tailRest)
    Right (Just suffix, tailRest) -> (TokenNumberWithSuffix value suffix, tailRest)

parseIntegerSuffix :: InputRest -> Either SuffixError SuffixParseResult
parseIntegerSuffix [] = Right (Nothing, [])
parseIntegerSuffix input@(c : _)
  | not (isSuffixChar c) = Right (Nothing, input)
  | otherwise =
      let (rawSuffix, tailRest) = span isSuffixChar input
          normalized = normalizeSuffix rawSuffix
       in case suffixFromNormalized normalized of
            Just suffix -> Right (Just suffix, tailRest)
            Nothing -> Left ("Invalid integer suffix: " ++ rawSuffix, tailRest)

isSuffixChar :: Char -> Bool
isSuffixChar ch = ch == 'u' || ch == 'U' || ch == 'l' || ch == 'L'

normalizeSuffix :: String -> String
normalizeSuffix = map toLowerAscii

toLowerAscii :: Char -> Char
toLowerAscii ch
  | ch >= 'A' && ch <= 'Z' = toEnum (fromEnum ch + 32)
  | otherwise = ch

suffixFromNormalized :: String -> Maybe IntSuffix
suffixFromNormalized "u" = Just SufU
suffixFromNormalized "l" = Just SufL
suffixFromNormalized "ul" = Just SufUL
suffixFromNormalized "lu" = Just SufUL
suffixFromNormalized _ = Nothing

-- Разбор строкового литерала с базовыми escape-последовательностями C.
lexStringLiteral :: String -> (Token, String)
lexStringLiteral input =
  case parseQuotedContent '"' input of
    Left (err, rest) -> (TokenLexError err, recoverAfterLiteralError '"' rest)
    Right (content, rest) -> (TokenStringLiteral content, rest)

-- Разбор символьного литерала: ровно один символ после раскодирования escape.
lexCharLiteral :: String -> (Token, String)
lexCharLiteral input =
  case parseQuotedContent '\'' input of
    Left (err, rest) -> (TokenLexError err, recoverAfterLiteralError '\'' rest)
    Right ([], rest) -> (TokenLexError "Invalid char literal: empty", rest)
    Right ([ch], rest) -> (TokenCharLiteral ch, rest)
    Right (_, rest) -> (TokenLexError "Invalid char literal: expected exactly one character", rest)

recoverAfterLiteralError :: Char -> String -> String
recoverAfterLiteralError delimiter input =
  case break (== delimiter) input of
    (_, []) -> []
    (_, _ : rest) -> rest

parseQuotedContent :: Char -> String -> Either (String, String) (String, String)
parseQuotedContent delimiter = go []
  where
    go _ [] = Left ("Unterminated literal", [])
    go acc (ch : rest)
      | ch == delimiter = Right (reverse acc, rest)
      | ch == '\\' =
          case decodeEscape rest of
            Left err -> Left (err, rest)
            Right (decoded, tailRest) -> go (decoded : acc) tailRest
      | otherwise = go (ch : acc) rest

decodeEscape :: String -> Either String (Char, String)
decodeEscape [] = Left "Invalid escape sequence: trailing backslash"

-- 2.2.2 Character Display Semantics
decodeEscape (ch : rest) =
  case ch of
    '\\' -> Right ('\\', rest) -- backslash
    '"' -> Right ('"', rest) -- double quote
    '\'' -> Right ('\'', rest) -- single quote
    'a' -> Right ('\a', rest) -- alert -- Produces an audible or visible alert. The active position shall not be changed.
    'b' -> Right ('\b', rest) -- backspace -- Moves the active position to the previous position on the current line. If the active position is at the initial position of a line, the behavior is unspecified.
    'f' -> Right ('\f', rest) -- form feed -- Moves the active position to the initial position at the start of the next logical page.
    'n' -> Right ('\n', rest) -- newline -- Moves the active position to the initial position of the next line.
    't' -> Right ('\t', rest) -- horizontal tab -- Moves the active position to the next horizontal tabulation position on the current line. If the active position is at or past the last defined horizontal tabulation position, the behavior is unspecified.
    'r' -> Right ('\r', rest) -- carriage return -- Moves the active position to the initial position of the current line.
    '0' -> Right ('\0', rest) -- null character -- The null character has no graphical representation.
    'v' -> Right ('\v', rest) -- vertical tab -- Moves the active position to the initial position of the next vertical tabulation position. If the active position is at or past the last defined vertical tabulation position, the behavior is unspecified.
    _ -> Left ("Invalid escape sequence: \\" ++ [ch])

-- Разбор операторов: сначала проверяем двухсимвольные, затем односимвольные.
lexOperator :: Char -> String -> (Token, String)
lexOperator c cs =
  case c : cs of
    '<' : '<' : '=' : rest -> (TokenLessLessEqual, rest)
    '>' : '>' : '=' : rest -> (TokenGreaterGreaterEqual, rest)
    '|' : '|' : rest -> (TokenPipePipe, rest)
    '&' : '&' : rest -> (TokenAmpersandAmpersand, rest)
    '+' : '+' : rest -> (TokenPlusPlus, rest)
    '-' : '-' : rest -> (TokenMinusMinus, rest)
    '<' : '<' : rest -> (TokenLessLess, rest)
    '>' : '>' : rest -> (TokenGreaterGreater, rest)
    '=' : '=' : rest -> (TokenEqual, rest)
    '!' : '=' : rest -> (TokenBangEqual, rest)
    '>' : '=' : rest -> (TokenGreaterEqual, rest)
    '<' : '=' : rest -> (TokenLessEqual, rest)
    '&' : '=' : rest -> (TokenAmpersandEqual, rest)
    '|' : '=' : rest -> (TokenPipeEqual, rest)
    '^' : '=' : rest -> (TokenCaretEqual, rest)
    '%' : '=' : rest -> (TokenPercentEqual, rest)
    '+' : '=' : rest -> (TokenPlusAssign, rest)
    '-' : '=' : rest -> (TokenMinusAssign, rest)
    '*' : '=' : rest -> (TokenMultiplyEqual, rest)
    '/' : '=' : rest -> (TokenDivideEqual, rest)
    '=' : rest -> (TokenAssign, rest)
    '+' : rest -> (TokenPlus, rest)
    '-' : rest -> (TokenMinus, rest)
    '*' : rest -> (TokenMultiply, rest)
    '/' : rest -> (TokenDivide, rest)
    ';' : rest -> (TokenSemicolon, rest)
    ',' : rest -> (TokenComma, rest)
    '.' : rest -> (TokenDot, rest)
    ':' : rest -> (TokenColon, rest)
    '?' : rest -> (TokenQuestion, rest)
    '!' : rest -> (TokenBang, rest)
    '#' : rest -> (TokenHash, rest)
    '%' : rest -> (TokenPercent, rest)
    '&' : rest -> (TokenAmpersand, rest)
    '|' : rest -> (TokenPipe, rest)
    '~' : rest -> (TokenTilde, rest)
    '^' : rest -> (TokenCaret, rest)
    '\\' : rest -> (TokenBackslash, rest)
    '(' : rest -> (TokenLeftParen, rest)
    ')' : rest -> (TokenRightParen, rest)
    '{' : rest -> (TokenLeftBrace, rest)
    '}' : rest -> (TokenRightBrace, rest)
    '[' : rest -> (TokenLeftBracket, rest)
    ']' : rest -> (TokenRightBracket, rest)
    '<' : rest -> (TokenLeftAngle, rest)
    '>' : rest -> (TokenRightAngle, rest)
    _ : rest -> (TokenSymbol c, rest)

classifyWord :: String -> Token
classifyWord word
  | Just token <- keywordToToken word = token
  | otherwise = TokenIdentifier word
