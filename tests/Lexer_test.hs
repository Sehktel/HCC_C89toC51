module Lexer_test (lexerAllTokensSpec, lexerABSpec, lexerTodoSpec, lexerMinimalSpec) where

import Control.Monad (forM_)
import Lexer (IntSuffix (..), Token (..), lexer)
import Preprocessor (preprocess)

import Test.Hspec (Spec, describe, it, shouldBe)

lexerMinimalSpec :: Spec
lexerMinimalSpec = 
  do
  describe "Preprocessor.preprocess" $ do
    it "удаляет пустые строки и обрезает края" $ do
      let input = "  int main() {  \n\n return 0; \n}\n"
      preprocess input `shouldBe` "int main() {\nreturn 0;\n}\n"

  describe "Lexer.lexer (базовая функция main)" $ do
    it "токенизирует базовую функцию main" $ do
      lexer "int main() { return 0; }"
        `shouldBe` [ TokenInt,
                     TokenIdentifier "main",
                     TokenLeftParen,
                     TokenRightParen,
                     TokenLeftBrace,
                     TokenReturn,
                     TokenNumber 0,
                     TokenSemicolon,
                     TokenRightBrace
                   ]
    it "токенизирует базовые операторы" $ do
      lexer "a==b; a!=b; a+=1; a-=2; a+b-c*d;"
        `shouldBe` [ TokenIdentifier "a",
                     TokenEqual,
                     TokenIdentifier "b",
                     TokenSemicolon,
                     TokenIdentifier "a",
                     TokenBangEqual,
                     TokenIdentifier "b",
                     TokenSemicolon,
                     TokenIdentifier "a",
                     TokenPlusAssign,
                     TokenNumber 1,
                     TokenSemicolon,
                     TokenIdentifier "a",
                     TokenMinusAssign,
                     TokenNumber 2,
                     TokenSemicolon,
                     TokenIdentifier "a",
                     TokenPlus,
                     TokenIdentifier "b",
                     TokenMinus,
                     TokenIdentifier "c",
                     TokenMultiply,
                     TokenIdentifier "d",
                     TokenSemicolon
                   ]

  describe "Lexer.lexer (минимальный идентификатор)" $ do
    it "разбирает один идентификатор" $ do
      lexer "a" `shouldBe` [TokenIdentifier "a"]
    it "разбирает одно число" $ do
      lexer "42" `shouldBe` [TokenNumber 42]
    it "разбирает 0x и 0-формы чисел" $ do
      lexer "0 077 0x1f 0X2A"
        `shouldBe` [ TokenNumber 0,
                     TokenNumber 63,
                     TokenNumber 31,
                     TokenNumber 42
                   ]
    it "разбирает 010 как восьмеричное число 8" $ do
      lexer "010" `shouldBe` [TokenNumber 8]
    it "возвращает ошибку на невалидное восьмеричное число 08" $ do
      lexer "08" `shouldBe` [TokenLexError "Invalid octal literal: 08"]
    it "возвращает ошибку на пустой шестнадцатеричный литерал 0x" $ do
      lexer "0x" `shouldBe` [TokenLexError "Invalid hexadecimal literal: 0x"]
    it "поддерживает суффиксы U/L/UL у целочисленных литералов" $ do
      lexer "10U 10l 10UL 0xFFu 077L"
        `shouldBe` [ TokenNumberWithSuffix 10 SufU,
                     TokenNumberWithSuffix 10 SufL,
                     TokenNumberWithSuffix 10 SufUL,
                     TokenNumberWithSuffix 255 SufU,
                     TokenNumberWithSuffix 63 SufL
                   ]
    it "разбирает согласованный набор числовых литералов" $ do
      lexer "0 00 075 09 0x1F 0X1f 123u 077L"
        `shouldBe` [ TokenNumber 0,
                     TokenNumber 0,
                     TokenNumber 61,
                     TokenLexError "Invalid octal literal: 09",
                     TokenNumber 31,
                     TokenNumber 31,
                     TokenNumberWithSuffix 123 SufU,
                     TokenNumberWithSuffix 63 SufL
                   ]
    it "возвращает ошибку на невалидный суффикс числа" $ do
      lexer "10UU" `shouldBe` [TokenLexError "Invalid integer suffix: UU"]
    it "корректно токенизирует переносы строк" $ do
      lexer "int main()\n{\nreturn 0x10;\n}\n"
        `shouldBe` [ TokenInt,
                     TokenIdentifier "main",
                     TokenLeftParen,
                     TokenRightParen,
                     TokenLeftBrace,
                     TokenReturn,
                     TokenNumber 16,
                     TokenSemicolon,
                     TokenRightBrace
                   ]
    it "разбирает строковый литерал с escape-последовательностями" $ do
      lexer "\"line\\n\\\"ok\\\"\""
        `shouldBe` [TokenStringLiteral "line\n\"ok\""]
    it "разбирает символьный литерал с escape-последовательностью" $ do
      lexer "'\\n'" `shouldBe` [TokenCharLiteral '\n']
    it "возвращает ошибку на незакрытый строковый литерал" $ do
      lexer "\"abc" `shouldBe` [TokenLexError "Unterminated literal"]
    it "возвращает ошибку на пустой символьный литерал" $ do
      lexer "''" `shouldBe` [TokenLexError "Invalid char literal: empty"]
    it "в strict C89 проекта запрещает многосимвольные char-константы" $ do
      lexer "'ab'" `shouldBe` [TokenLexError "Invalid char literal: expected exactly one character"]
    it "возвращает ошибку на невалидный escape в строке" $ do
      lexer "\"\\q\"" `shouldBe` [TokenLexError "Invalid escape sequence: \\q"]

lexerAllTokensSpec :: Spec
lexerAllTokensSpec =
  do
    describe "Lexer.lexer (одна большая строка со всеми токенами)" $ do
      it "разбирает большую строку в ожидаемую последовательность токенов" $ do
        lexer input `shouldBe` expected

    describe "Lexer.lexer (минимальный идентификатор)" $ do
      it "разбирает один идентификатор" $ do
        lexer smallInput `shouldBe` smallExpected

    describe "Lexer.lexer (минимальное число)" $ do
      it "разбирает одно число" $ do
        lexer "42" `shouldBe` [TokenNumber 42]

  where
    -- Одна большая строка: ключевые слова, идентификатор/число, операторы и разделители.
    input = "one of auto double int struct break else long switch case enum register typedef char extern return union const float short unsigned continue for signed void default goto sizeof volatile do if static while sfr sfr16 sbit sft bit data idata pdata xdata code interrupt using reentrant _at_ ident 42 = == != + += ++ - -= -- * *= / /= ; , . : ? ! # % %= & && &= | || |= ~ ^ ^= \\ \"s\" 'x' ( ) { } [ ] < <= << <<= > >= >> >>="
    expected =
      [ TokenOne, TokenOf, TokenAuto, TokenDouble, TokenInt, TokenStruct, TokenBreak, TokenElse, TokenLong
      , TokenSwitch, TokenCase, TokenEnum, TokenRegister, TokenTypedef, TokenChar, TokenExtern, TokenReturn
      , TokenUnion, TokenConst, TokenFloat, TokenShort, TokenUnsigned, TokenContinue, TokenFor, TokenSigned
      , TokenVoid, TokenDefault, TokenGoto, TokenSizeof, TokenVolatile, TokenDo, TokenIf, TokenStatic
      , TokenWhile, TokenSfr, TokenSfr16, TokenSbit, TokenSft, TokenBit, TokenData, TokenIdata, TokenPdata
      , TokenXdata, TokenCode, TokenInterrupt, TokenUsing, TokenReentrant, TokenAt, TokenIdentifier "ident"
      , TokenNumber 42, TokenAssign, TokenEqual, TokenBangEqual, TokenPlus, TokenPlusAssign, TokenPlusPlus, TokenMinus
      , TokenMinusAssign, TokenMinusMinus, TokenMultiply, TokenMultiplyEqual, TokenDivide, TokenDivideEqual
      , TokenSemicolon, TokenComma, TokenDot, TokenColon, TokenQuestion, TokenBang, TokenHash, TokenPercent
      , TokenPercentEqual, TokenAmpersand, TokenAmpersandAmpersand, TokenAmpersandEqual, TokenPipe
      , TokenPipePipe, TokenPipeEqual, TokenTilde, TokenCaret, TokenCaretEqual, TokenBackslash
      , TokenStringLiteral "s", TokenCharLiteral 'x', TokenLeftParen, TokenRightParen, TokenLeftBrace, TokenRightBrace, TokenLeftBracket
      , TokenRightBracket, TokenLeftAngle, TokenLessEqual, TokenLessLess, TokenLessLessEqual, TokenRightAngle
      , TokenGreaterEqual, TokenGreaterGreater, TokenGreaterGreaterEqual
      ]

    smallInput = "a"
    smallExpected = [TokenIdentifier "a"]

lexerABSpec :: Spec
lexerABSpec =
  describe "Lexer.lexer (короткие идентификаторы)" $
    forM_ cases $ \(input, expected) ->
      it ("разбирает " ++ show input) $
--        lexer input `shouldBe` [TokenIdentifier expected]
        shouldBe (lexer input) [TokenIdentifier expected]
  where
    cases =
      [ ("a", "a"),
        ("b", "b"),
        ("ab", "ab")
      ]

lexerTodoSpec :: Spec
lexerTodoSpec =
  describe "Lexer TODO" $ do
    it "строковые и символьные литералы покрыты тестами" $ do
      lexer "\"ok\" 'a'" `shouldBe` [TokenStringLiteral "ok", TokenCharLiteral 'a']