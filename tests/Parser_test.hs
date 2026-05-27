module Parser_test (parserSpec) where

import Control.Monad (forM_)
import Lexer (Token (..), lexer)
import Logger (Logger, silentLogger)
import Parser (AssignOp (..), Ast (..), BinOp (..), Expr (..), parseTokens)
import SrcCFixtures (discoverParserFixtures, goldenParserExt, goldenParserLegacyExt, trim)
import System.Directory (doesFileExist)
import System.FilePath (replaceExtension)
import Test.Hspec (Spec, describe, expectationFailure, it, runIO, shouldBe)
import Preprocessor (defaultPreprocessConfig, preprocess)
import TestManifest (ManifestCase (..), loadCasesByPackage, matchTextExpectation)
import TestMatrix (recordCompare, shouldBeRecorded)

parserSpec :: Spec
parserSpec = do
  fixtures <- runIO discoverParserFixtures
  manifestCases <- runIO (loadCasesByPackage "tests/test-manifest.json" "Parser")
  let lg = silentLogger
  describe "Parser.parseTokens" $ do
    -- Формат fixture:
    -- *.c   -> исходник
    -- *.p   -> ожидаемое дерево парсера (в формате Show, приоритетный формат)
    -- *.ast -> legacy-формат (для обратной совместимости)
    -- Поддерживается вложенная структура директорий.
    forM_ fixtures (assertFixtureByPath lg)
    forM_ manifestCases (assertManifestCase lg)

    describe "приоритет операций (дерево Expr)" $ do
      it "умножение жёстче сложения: a+b*c → a+(b*c)" $ do
        checkParseMainReturn lg "умножение: a+b*c" "int main(){ return a+b*c; }\n" (ExprBinary OpAdd (ExprVar "a") (ExprBinary OpMul (ExprVar "b") (ExprVar "c")))

      it "умножение жёстче сложения слева: a*b+c → (a*b)+c" $ do
        checkParseMainReturn lg "умножение слева: a*b+c" "int main(){ return a*b+c; }\n" (ExprBinary OpAdd (ExprBinary OpMul (ExprVar "a") (ExprVar "b")) (ExprVar "c"))

      it "сложение левоассоциативно: a-b-c → (a-b)-c" $ do
        checkParseMainReturn lg "сложение: a-b-c" "int main(){ return a-b-c; }\n" (ExprBinary OpSub (ExprBinary OpSub (ExprVar "a") (ExprVar "b")) (ExprVar "c"))

      it "сдвиг слабее сложения: a<<b+c → a<<(b+c)" $ do
        checkParseMainReturn lg "сдвиг: a<<b+c" "int main(){ return a<<b+c; }\n" (ExprBinary OpShl (ExprVar "a") (ExprBinary OpAdd (ExprVar "b") (ExprVar "c")))

      it "сложение жёстче равенства: a+b==c → (a+b)==c" $ do
        checkParseMainReturn lg "сложение и ==: a+b==c" "int main(){ return a+b==c; }\n" (ExprBinary OpEq (ExprBinary OpAdd (ExprVar "a") (ExprVar "b")) (ExprVar "c"))

      it "побитовое И жёстче ИЛИ: a|b&c → a|(b&c)" $ do
        checkParseMainReturn lg "побитовое: a|b&c" "int main(){ return a|b&c; }\n" (ExprBinary OpBitOr (ExprVar "a") (ExprBinary OpBitAnd (ExprVar "b") (ExprVar "c")))

      it "побитовое XOR между И и ИЛИ: a^b|c → (a^b)|c" $ do
        checkParseMainReturn lg "XOR: a^b|c" "int main(){ return a^b|c; }\n" (ExprBinary OpBitOr (ExprBinary OpBitXor (ExprVar "a") (ExprVar "b")) (ExprVar "c"))

      it "логическое И жёстче ИЛИ: a||b&&c → a||(b&&c)" $ do
        checkParseMainReturn lg "логическое: a||b&&c" "int main(){ return a||b&&c; }\n" (ExprBinary OpOr (ExprVar "a") (ExprBinary OpAnd (ExprVar "b") (ExprVar "c")))

      it "скобки переопределяют приоритет: (a+b)*c" $ do
        checkParseMainReturn lg "скобки: (a+b)*c" "int main(){ return (a+b)*c; }\n" (ExprBinary OpMul (ExprBinary OpAdd (ExprVar "a") (ExprVar "b")) (ExprVar "c"))

      it "тернарный оператор правоассоциативен: a?b:c?d:e → a?b:(c?d:e)" $ do
        checkParseMainReturn lg "тернарный: a?b:c?d:e" "int main(){ return a?b:c?d:e; }\n" (ExprTernary (ExprVar "a") (ExprVar "b") (ExprTernary (ExprVar "c") (ExprVar "d") (ExprVar "e")))

      it "присваивание правоассоциативно: a=b=c" $ do
        checkParseMainReturn lg "присваивание: a=b=c" "int main(){ return a=b=c; }\n" (ExprAssign AAssign (ExprVar "a") (ExprAssign AAssign (ExprVar "b") (ExprVar "c")))

      it "композиция: отношение и равенство — a<b==c → (a<b)==c" $ do
        checkParseMainReturn lg "отношение и ==: a<b==c" "int main(){ return a<b==c; }\n" (ExprBinary OpEq (ExprBinary OpLt (ExprVar "a") (ExprVar "b")) (ExprVar "c"))

    it "возвращает AstUnknown для неподдерживаемого паттерна токенов" $ do
      let toks = [TokenInt, TokenIdentifier "x"]
      ast <- parseTokens lg toks
      let expected = AstUnknown toks
      recordCompare "Parser" "AstUnknown" (show toks) (show expected) (show ast)
      ast `shouldBe` expected

assertFixtureByPath :: Logger -> FilePath -> Spec
assertFixtureByPath lg cFile =
  it ("парсит fixture " ++ cFile) $ do
    source <- readFile cFile
    expectationFile <- parserExpectationFile cFile
    expectedAst <- readFile expectationFile
    toks <- lexer lg source
    actualAst <- parseTokens lg toks
    let actual = show actualAst
    let expTrim = trim expectedAst
    recordCompare "Parser fixture" cFile source expTrim actual
    actual `shouldBe` expTrim
  where
    parserExpectationFile filePath = do
      let pFile = replaceExtension filePath goldenParserExt
      hasP <- doesFileExist pFile
      pure $
        if hasP
          then pFile
          else replaceExtension filePath goldenParserLegacyExt

-- | Разобрать минимальную программу с одним return и вернуть выражение (для проверки дерева).
checkParseMainReturn :: Logger -> String -> String -> Expr -> IO ()
checkParseMainReturn lg name inp expected = do
  r <- parseMainReturn lg inp
  case r of
    Right expr -> shouldBeRecorded "Parser (приоритет)" name inp expected expr
    Left err -> expectationFailure err

parseMainReturn :: Logger -> String -> IO (Either String Expr)
parseMainReturn lg raw = do
  src <- preprocess defaultPreprocessConfig Nothing raw
  toks <- lexer lg src
  ast <- parseTokens lg toks
  pure $ case ast of
    AstProgram [AstFunctionDef "main" _ _ (AstCompound [AstReturn (Just e)])] -> Right e
    x -> Left ("ожидался main с одним return, получено: " ++ show x)

assertManifestCase :: Logger -> ManifestCase -> Spec
assertManifestCase lg mc =
  it ("manifest: " ++ mcName mc) $ do
    source <- readFile (mcInputFile mc)
    expectedAst <- readFile (mcOutputFile mc)
    toks <- lexer lg source
    ast <- parseTokens lg toks
    let actual = show ast
    let expTrim = trim expectedAst
    case matchTextExpectation (mcExpectation mc) actual expTrim of
      Right matched -> do
        recordCompare ("Manifest [" ++ mcPackage mc ++ "]") (mcName mc) source expTrim actual
        matched `shouldBe` True
      Left err -> expectationFailure err
