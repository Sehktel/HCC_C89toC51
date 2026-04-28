module Lexer (IntSuffix (..), Token (..), lexer) where

import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)

data Token
  = TokenOne -- "one"
  | TokenOf -- "of"
  | TokenAuto -- "auto"
  | TokenDouble -- "double"
  | TokenInt -- "int"
  | TokenStruct -- "struct"
  | TokenBreak -- "break"
  | TokenElse -- "else"
  | TokenLong -- "long"
  | TokenSwitch -- "switch"
  | TokenCase -- "case"
  | TokenEnum -- "enum"
  | TokenRegister -- "register"
  | TokenTypedef -- "typedef"
  | TokenChar -- "char"
  | TokenExtern -- "extern"
  | TokenReturn -- "return"
  | TokenUnion -- "union"
  | TokenConst -- "const"
  | TokenFloat -- "float"
  | TokenShort -- "short"
  | TokenUnsigned -- "unsigned"
  | TokenContinue -- "continue"
  | TokenFor -- "for"
  | TokenSigned -- "signed"
  | TokenVoid -- "void"
  | TokenDefault -- "default"
  | TokenGoto -- "goto"
  | TokenSizeof -- "sizeof"
  | TokenVolatile -- "volatile"
  | TokenDo -- "do"
  | TokenIf -- "if"
  | TokenStatic -- "static"
  | TokenWhile -- "while" 
  | TokenSfr -- "sfr"
  | TokenSfr16 -- "sfr16"
  | TokenSbit -- "sbit"
  | TokenSft -- "sft"
  | TokenBit -- "bit"
  | TokenData -- "data"
  | TokenIdata -- "idata"
  | TokenPdata -- "pdata"
  | TokenXdata -- "xdata"
  | TokenCode -- "code"
  | TokenInterrupt -- "interrupt"
  | TokenUsing -- "using"
  | TokenReentrant -- "reentrant"
  | TokenAt -- "_at_"
  | TokenAssign -- "="
  | TokenEqual -- "=="
  | TokenPlus -- "+"
  | TokenPlusAssign -- "+="
  | TokenMinus -- "-"
  | TokenMinusAssign -- "-="
  | TokenMultiply -- "*"
  | TokenDivide -- "/"
  | TokenSemicolon -- ";"
  | TokenComma -- ","
  | TokenDot -- "."
  | TokenColon -- ":"
  | TokenQuestion -- "?"
  | TokenBang -- "!"
  | TokenHash -- "#"
  | TokenPercent -- "%"
  | TokenAmpersand -- "&"
  | TokenPipe -- "|"
  | TokenTilde -- "~"
  | TokenCaret -- "^"
  | TokenBackslash -- "\\"
  | TokenLeftParen -- "("
  | TokenRightParen -- ")"
  | TokenLeftBrace -- "{"
  | TokenRightBrace -- "}"
  | TokenLeftBracket -- "["
  | TokenRightBracket -- "]"
  | TokenLeftAngle -- "<"
  | TokenRightAngle -- ">"
  | TokenPipePipe -- "||"
  | TokenAmpersandAmpersand -- "&&"
  | TokenPlusPlus -- "++"
  | TokenMinusMinus -- "--"
  | TokenLessLess -- "<<"
  | TokenGreaterGreater -- ">>"
  | TokenLessLessEqual -- "<<="
  | TokenGreaterGreaterEqual -- ">>="
  | TokenBangEqual -- "!="
  | TokenGreaterEqual -- ">="
  | TokenLessEqual -- "<="
  | TokenAmpersandEqual -- "&="
  | TokenPipeEqual -- "|="
  | TokenCaretEqual -- "^="
  | TokenPercentEqual -- "%="
  | TokenMultiplyEqual -- "*="
  | TokenDivideEqual -- "/="
  | TokenIdentifier String -- identifier
  | TokenNumber Int -- number
  | TokenNumberWithSuffix Int IntSuffix -- integer with C suffix
  | TokenStringLiteral String -- string literal
  | TokenCharLiteral Char -- character literal
  | TokenLexError String -- lexer error
  | TokenSymbol Char -- symbol
  deriving (Eq, Show)

data IntSuffix
  = SufU
  | SufL
  | SufUL
  deriving (Eq, Show)

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
keywordToToken "pdata" = Just TokenPdata
keywordToToken "xdata" = Just TokenXdata
keywordToToken "code" = Just TokenCode
keywordToToken "interrupt" = Just TokenInterrupt
keywordToToken "using" = Just TokenUsing
keywordToToken "reentrant" = Just TokenReentrant
keywordToToken "_at_" = Just TokenAt
keywordToToken _ = Nothing



-- Минимальный лексер: разбирает идентификаторы, ключевые слова, числа и символы.
lexer :: String -> [Token]
lexer [] = []
lexer (c : cs)
  | isSpace c = lexer cs
  | c == '"' =
      let (stringToken, rest) = lexStringLiteral cs
       in stringToken : lexer rest
  | c == '\'' =
      let (charToken, rest) = lexCharLiteral cs
       in charToken : lexer rest
  | isAlpha c || c == '_' =
      let (name, rest) = span (\x -> isAlphaNum x || x == '_') (c : cs)
       in classifyWord name : lexer rest
  | isDigit c =
      let (numberToken, rest) = lexNumber (c : cs)
       in numberToken : lexer rest
  | otherwise =
      let (token, rest) = lexOperator c cs
       in token : lexer rest

-- Разбор чисел: поддержка десятичных, шестнадцатеричных (0x) и восьмеричных (0...).
lexNumber :: String -> (Token, String)
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

lexHexNumber :: String -> (Token, String)
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
attachIntegerSuffix :: Int -> String -> (Token, String)
attachIntegerSuffix value rest =
  case parseIntegerSuffix rest of
    Left (err, tailRest) -> (TokenLexError err, tailRest)
    Right (Nothing, tailRest) -> (TokenNumber value, tailRest)
    Right (Just suffix, tailRest) -> (TokenNumberWithSuffix value suffix, tailRest)

parseIntegerSuffix :: String -> Either (String, String) (Maybe IntSuffix, String)
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
decodeEscape (ch : rest) =
  case ch of
    '\\' -> Right ('\\', rest)
    '"' -> Right ('"', rest)
    '\'' -> Right ('\'', rest)
    'n' -> Right ('\n', rest)
    't' -> Right ('\t', rest)
    'r' -> Right ('\r', rest)
    '0' -> Right ('\0', rest)
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
