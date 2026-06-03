module Lexer_test (lexerAllTokensSpec, lexerABSpec, lexerTodoSpec, lexerMinimalSpec, lexerFixtureSpec) where

import Control.Monad (forM_)
import Lexer (IntSuffix (..), Token (..), lexer, lexerPure)
import Logger (silentLogger)
import Preprocessor (defaultPreprocessConfig, preprocess)
import SrcCFixtures (discoverLexerFixtures, goldenPreprocessorExt, srcCPreprocessConfig, trim)
import System.Directory (doesFileExist)
import System.FilePath (replaceExtension)
import Test.Hspec (Spec, describe, expectationFailure, it, runIO, shouldBe)
import TestManifest (ManifestCase (..), loadCasesByPackage, matchTextExpectation)
import TestMatrix (recordCompare, shouldBeRecorded, shouldBeTextRecorded)

-- | Лексер + запись в test-matrix.json (только при initMatrix в test-web-report).
lexShouldBe :: String -> String -> [Token] -> IO ()
lexShouldBe name inp expected =
  shouldBeRecorded "Lexer" name inp expected (lexerPure inp)

lexerMinimalSpec :: Spec
lexerMinimalSpec =
  do
    describe "Preprocessor.preprocess" $ do
      it "удаляет пустые строки и обрезает края" $ do
        let input = "  int main() {  \n\n return 0; \n}\n"
        shouldBeTextRecorded "Preprocessor" "удаляет пустые строки и обрезает края" input "int main() {\nreturn 0;\n}\n" (preprocess defaultPreprocessConfig Nothing input)

    describe "Lexer.lexer (базовая функция main)" $ do
      it "lexer silentLogger совпадает с lexerPure (обёртка с логом)" $ do
        let sample = "int x; void f() {}\n"
        got <- lexer silentLogger sample
        let expected = lexerPure sample
        recordCompare "Lexer" "lexer silentLogger ≡ lexerPure" sample (show expected) (show got)
        got `shouldBe` expected
      it "токенизирует базовую функцию main" $ do
        let inp = "int main() { return 0; }"
        let expected =
              [ TokenInt,
                       TokenIdentifier "main",
                       TokenLeftParen,
                       TokenRightParen,
                       TokenLeftBrace,
                       TokenReturn,
                       TokenNumber 0,
                       TokenSemicolon,
                       TokenRightBrace
                     ]
        shouldBeRecorded "Lexer" "токенизирует базовую функцию main" inp expected (lexerPure inp)
      it "токенизирует базовые операторы" $ do
        let inp = "a==b; a!=b; a+=1; a-=2; a+b-c*d;"
        let expected =
              [ TokenIdentifier "a",
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
        shouldBeRecorded "Lexer" "токенизирует базовые операторы" inp expected (lexerPure inp)

    describe "Lexer.lexer (минимальный идентификатор)" $ do
      it "разбирает один идентификатор" $ do
        lexShouldBe "разбирает один идентификатор" "a" [TokenIdentifier "a"]
      it "разбирает одно число" $ do
        lexShouldBe "разбирает одно число" "42" [TokenNumber 42]
      it "разбирает 0x и 0-формы чисел" $ do
        let inp = "0 077 0x1f 0X2A"
        let expected =
              [ TokenNumber 0,
                       TokenNumber 63,
                       TokenNumber 31,
                       TokenNumber 42
                     ]
        shouldBeRecorded "Lexer" "разбирает 0x и 0-формы чисел" inp expected (lexerPure inp)
      it "разбирает 010 как восьмеричное число 8" $ do
        lexShouldBe "разбирает 010 как восьмеричное 8" "010" [TokenNumber 8]
      it "возвращает ошибку на невалидное восьмеричное число 08" $ do
        lexShouldBe "ошибка: восьмеричное 08" "08" [TokenLexError "Invalid octal literal: 08"]
      it "возвращает ошибку на пустой шестнадцатеричный литерал 0x" $ do
        lexShouldBe "ошибка: пустой hex 0x" "0x" [TokenLexError "Invalid hexadecimal literal: 0x"]
      it "поддерживает суффиксы U/L/UL у целочисленных литералов" $ do
        let inp = "10U 10l 10UL 0xFFu 077L"
        let expected =
              [ TokenNumberWithSuffix 10 SufU,
                       TokenNumberWithSuffix 10 SufL,
                       TokenNumberWithSuffix 10 SufUL,
                       TokenNumberWithSuffix 255 SufU,
                       TokenNumberWithSuffix 63 SufL
                     ]
        shouldBeRecorded "Lexer" "суффиксы U/L/UL" inp expected (lexerPure inp)
      it "разбирает согласованный набор числовых литералов" $ do
        let inp = "0 00 075 09 0x1F 0X1f 123u 077L"
        let expected =
              [ TokenNumber 0,
                       TokenNumber 0,
                       TokenNumber 61,
                       TokenLexError "Invalid octal literal: 09",
                       TokenNumber 31,
                       TokenNumber 31,
                       TokenNumberWithSuffix 123 SufU,
                       TokenNumberWithSuffix 63 SufL
                     ]
        shouldBeRecorded "Lexer" "согласованный набор числовых литералов" inp expected (lexerPure inp)
      it "возвращает ошибку на невалидный суффикс числа" $ do
        lexShouldBe "ошибка: суффикс 10UU" "10UU" [TokenLexError "Invalid integer suffix: UU"]
      it "корректно токенизирует переносы строк" $ do
        let inp = "int main()\n{\nreturn 0x10;\n}\n"
        let expected =
              [ TokenInt,
                       TokenIdentifier "main",
                       TokenLeftParen,
                       TokenRightParen,
                       TokenLeftBrace,
                       TokenReturn,
                       TokenNumber 16,
                       TokenSemicolon,
                       TokenRightBrace
                     ]
        shouldBeRecorded "Lexer" "переносы строк" inp expected (lexerPure inp)
      it "разбирает строковый литерал с escape-последовательностями" $ do
        lexShouldBe "строковый литерал с escape" "\"line\\n\\\"ok\\\"\"" [TokenStringLiteral "line\n\"ok\""]
      it "разбирает символьный литерал с escape-последовательностью" $ do
        lexShouldBe "символьный литерал" "'\\n'" [TokenCharLiteral '\n']
      it "возвращает ошибку на незакрытый строковый литерал" $ do
        lexShouldBe "незакрытый строковый литерал" "\"abc" [TokenLexError "Unterminated literal"]
      it "возвращает ошибку на пустой символьный литерал" $ do
        lexShouldBe "пустой char" "''" [TokenLexError "Invalid char literal: empty"]
      it "в strict C89 проекта запрещает многосимвольные char-константы" $ do
        lexShouldBe "многосимвольный char" "'ab'" [TokenLexError "Invalid char literal: expected exactly one character"]
      it "возвращает ошибку на невалидный escape в строке" $ do
        lexShouldBe "невалидный escape" "\"\\q\"" [TokenLexError "Invalid escape sequence: \\q"]

lexerAllTokensSpec :: Spec
lexerAllTokensSpec =
  do
    describe "Lexer.lexer (одна большая строка со всеми токенами)" $ do
      it "разбирает большую строку в ожидаемую последовательность токенов" $ do
        shouldBeRecorded "Lexer" "большая строка (all tokens)" input expected (lexerPure input)

    describe "Lexer.lexer (минимальный идентификатор)" $ do
      it "разбирает один идентификатор" $ do
        lexShouldBe "all-tokens: идентификатор a" smallInput smallExpected

    describe "Lexer.lexer (минимальное число)" $ do
      it "разбирает одно число" $ do
        lexShouldBe "all-tokens: число 42" "42" [TokenNumber 42]

  where
    -- Одна большая строка: ключевые слова, идентификатор/число, операторы и разделители.
    input = "one of auto double int struct break else long switch case enum register typedef char extern return union const float short unsigned continue for signed void default goto sizeof volatile do if static while sfr sfr16 sbit sft bit data idata bdata pdata xdata code interrupt using reentrant _at_ ident 42 = == != + += ++ - -= -- * *= / /= ; , . : ? ! # % %= & && &= | || |= ~ ^ ^= \\ \"s\" 'x' ( ) { } [ ] < <= << <<= > >= >> >>="
    expected =
      [ TokenOne, TokenOf, TokenAuto, TokenDouble, TokenInt, TokenStruct, TokenBreak, TokenElse, TokenLong
      , TokenSwitch, TokenCase, TokenEnum, TokenRegister, TokenTypedef, TokenChar, TokenExtern, TokenReturn
      , TokenUnion, TokenConst, TokenFloat, TokenShort, TokenUnsigned, TokenContinue, TokenFor, TokenSigned
      , TokenVoid, TokenDefault, TokenGoto, TokenSizeof, TokenVolatile, TokenDo, TokenIf, TokenStatic
      , TokenWhile, TokenSfr, TokenSfr16, TokenSbit, TokenSft, TokenBit, TokenData, TokenIdata, TokenBdata, TokenPdata
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
        lexShouldBe ("lexerAB: " ++ input) input [TokenIdentifier expected]
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
      lexShouldBe "lexerTodo: строка и char" "\"ok\" 'a'" [TokenStringLiteral "ok", TokenCharLiteral 'a']

lexerFixtureSpec :: Spec
lexerFixtureSpec = do
  fixtures <- runIO discoverLexerFixtures
  manifestCases <- runIO (loadCasesByPackage "tests/test-manifest.json" "Lexer")
  describe "Lexer fixtures (.l)" $ do
    forM_ fixtures $ \cFile ->
      it ("токенизирует fixture " ++ cFile) $ do
        source <- readFile cFile
        expected <- readFile (replaceExtension cFile ".l")
        let ppFile = replaceExtension cFile goldenPreprocessorExt
        -- Эталон .l — post-PP; вход лексера — .pp (выход PP), не preprocess(.c)
        src <- do
          hasPp <- doesFileExist ppFile
          if hasPp then readFile ppFile else preprocess srcCPreprocessConfig (Just cFile) source
        let actual = show (lexerPure src)
        recordCompare "Lexer fixture" cFile source (trim expected) actual
        actual `shouldBe` trim expected
    forM_ manifestCases assertLexerManifestCase

assertLexerManifestCase :: ManifestCase -> Spec
assertLexerManifestCase mc =
  it ("manifest: " ++ mcName mc) $ do
    source <- readFile (mcInputFile mc)
    expected <- readFile (mcOutputFile mc)
    let actual = show (lexerPure source)
    let expTrim = trim expected
    case matchTextExpectation (mcExpectation mc) actual expTrim of
      Right matched -> do
        recordCompare ("Manifest [" ++ mcPackage mc ++ "]") (mcName mc) source expTrim actual
        matched `shouldBe` True
      Left err -> expectationFailure err
