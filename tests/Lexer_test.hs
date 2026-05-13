module Lexer_test (lexerAllTokensSpec, lexerABSpec, lexerTodoSpec, lexerMinimalSpec, lexerFixtureSpec) where

import Control.Monad (filterM, forM, forM_)
import Data.Char (isSpace)
import Data.List (nub, sort)
import Lexer (IntSuffix (..), Token (..), lexer, lexerPure)
import Logger (silentLogger)
import Preprocessor (defaultPreprocessConfig, preprocess)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath ((</>), replaceExtension, takeExtension)
import Test.Hspec (Spec, describe, expectationFailure, it, runIO, shouldBe)
import TestManifest (ManifestCase (..), loadCasesByPackage, matchTextExpectation)

lexerMinimalSpec :: Spec
lexerMinimalSpec =
  do
    describe "Preprocessor.preprocess" $ do
      it "удаляет пустые строки и обрезает края" $ do
        let input = "  int main() {  \n\n return 0; \n}\n"
        out <- preprocess defaultPreprocessConfig Nothing input
        out `shouldBe` "int main() {\nreturn 0;\n}\n"

    describe "Lexer.lexer (базовая функция main)" $ do
      it "lexer silentLogger совпадает с lexerPure (обёртка с логом)" $ do
        let sample = "int x; void f() {}\n"
        got <- lexer silentLogger sample
        got `shouldBe` lexerPure sample
      it "токенизирует базовую функцию main" $ do
        lexerPure "int main() { return 0; }"
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
        lexerPure "a==b; a!=b; a+=1; a-=2; a+b-c*d;"
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
        lexerPure "a" `shouldBe` [TokenIdentifier "a"]
      it "разбирает одно число" $ do
        lexerPure "42" `shouldBe` [TokenNumber 42]
      it "разбирает 0x и 0-формы чисел" $ do
        lexerPure "0 077 0x1f 0X2A"
          `shouldBe` [ TokenNumber 0,
                       TokenNumber 63,
                       TokenNumber 31,
                       TokenNumber 42
                     ]
      it "разбирает 010 как восьмеричное число 8" $ do
        lexerPure "010" `shouldBe` [TokenNumber 8]
      it "возвращает ошибку на невалидное восьмеричное число 08" $ do
        lexerPure "08" `shouldBe` [TokenLexError "Invalid octal literal: 08"]
      it "возвращает ошибку на пустой шестнадцатеричный литерал 0x" $ do
        lexerPure "0x" `shouldBe` [TokenLexError "Invalid hexadecimal literal: 0x"]
      it "поддерживает суффиксы U/L/UL у целочисленных литералов" $ do
        lexerPure "10U 10l 10UL 0xFFu 077L"
          `shouldBe` [ TokenNumberWithSuffix 10 SufU,
                       TokenNumberWithSuffix 10 SufL,
                       TokenNumberWithSuffix 10 SufUL,
                       TokenNumberWithSuffix 255 SufU,
                       TokenNumberWithSuffix 63 SufL
                     ]
      it "разбирает согласованный набор числовых литералов" $ do
        lexerPure "0 00 075 09 0x1F 0X1f 123u 077L"
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
        lexerPure "10UU" `shouldBe` [TokenLexError "Invalid integer suffix: UU"]
      it "корректно токенизирует переносы строк" $ do
        lexerPure "int main()\n{\nreturn 0x10;\n}\n"
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
        lexerPure "\"line\\n\\\"ok\\\"\""
          `shouldBe` [TokenStringLiteral "line\n\"ok\""]
      it "разбирает символьный литерал с escape-последовательностью" $ do
        lexerPure "'\\n'" `shouldBe` [TokenCharLiteral '\n']
      it "возвращает ошибку на незакрытый строковый литерал" $ do
        lexerPure "\"abc" `shouldBe` [TokenLexError "Unterminated literal"]
      it "возвращает ошибку на пустой символьный литерал" $ do
        lexerPure "''" `shouldBe` [TokenLexError "Invalid char literal: empty"]
      it "в strict C89 проекта запрещает многосимвольные char-константы" $ do
        lexerPure "'ab'" `shouldBe` [TokenLexError "Invalid char literal: expected exactly one character"]
      it "возвращает ошибку на невалидный escape в строке" $ do
        lexerPure "\"\\q\"" `shouldBe` [TokenLexError "Invalid escape sequence: \\q"]

lexerAllTokensSpec :: Spec
lexerAllTokensSpec =
  do
    describe "Lexer.lexer (одна большая строка со всеми токенами)" $ do
      it "разбирает большую строку в ожидаемую последовательность токенов" $ do
        lexerPure input `shouldBe` expected

    describe "Lexer.lexer (минимальный идентификатор)" $ do
      it "разбирает один идентификатор" $ do
        lexerPure smallInput `shouldBe` smallExpected

    describe "Lexer.lexer (минимальное число)" $ do
      it "разбирает одно число" $ do
        lexerPure "42" `shouldBe` [TokenNumber 42]

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
        shouldBe (lexerPure input) [TokenIdentifier expected]
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
      lexerPure "\"ok\" 'a'" `shouldBe` [TokenStringLiteral "ok", TokenCharLiteral 'a']

lexerFixtureSpec :: Spec
lexerFixtureSpec = do
  fixtures <- runIO discoverLexerFixtures
  manifestCases <- runIO (loadCasesByPackage "tests/test-manifest.json" "Lexer")
  describe "Lexer fixtures (.l)" $ do
    forM_ fixtures $ \cFile ->
      it ("токенизирует fixture " ++ cFile) $ do
        source <- readFile cFile
        expected <- readFile (replaceExtension cFile ".l")
        show (lexerPure source) `shouldBe` trim expected
    forM_ manifestCases assertLexerManifestCase

discoverLexerFixtures :: IO [FilePath]
discoverLexerFixtures = do
  cFiles <- findFilesByExtension "tests/src_c" ".c"
  paired <- filterM hasLexerExpectation cFiles
  pure (sort (nub paired))
  where
    hasLexerExpectation cFile = doesFileExist (replaceExtension cFile ".l")

findFilesByExtension :: FilePath -> String -> IO [FilePath]
findFilesByExtension root extension = do
  exists <- doesDirectoryExist root
  if not exists
    then pure []
    else go root
  where
    go dir = do
      names <- listDirectory dir
      nested <- forM names $ \name -> do
        let path = dir </> name
        isDir <- doesDirectoryExist path
        if isDir
          then go path
          else pure [path | takeExtension path == extension]
      pure (concat nested)

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

dropWhileEnd :: (Char -> Bool) -> String -> String
dropWhileEnd predicate = reverse . dropWhile predicate . reverse

assertLexerManifestCase :: ManifestCase -> Spec
assertLexerManifestCase mc =
  it ("manifest: " ++ mcName mc) $ do
    source <- readFile (mcInputFile mc)
    expected <- readFile (mcOutputFile mc)
    let actual = show (lexerPure source)
    case matchTextExpectation (mcExpectation mc) actual (trim expected) of
      Right matched -> matched `shouldBe` True
      Left err -> expectationFailure err
