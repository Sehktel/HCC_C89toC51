module Parser_test (parserSpec) where

import Control.Monad (filterM, forM, forM_)
import Data.Char (isSpace)
import Data.List (sort)
import Lexer (Token (..), lexer)
import Parser (AssignOp (..), Ast (..), BinOp (..), Expr (..), parseTokens)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath ((</>), replaceExtension, takeExtension)
import Test.Hspec (Spec, describe, expectationFailure, it, runIO, shouldBe)
import Preprocessor (preprocess)
import TestManifest (ManifestCase (..), loadCasesByPackage, matchTextExpectation)

parserSpec :: Spec
parserSpec = do
  fixtures <- runIO discoverParserFixtures
  manifestCases <- runIO (loadCasesByPackage "tests/test-manifest.json" "Parser")
  describe "Parser.parseTokens" $ do
    -- Формат fixture:
    -- *.c   -> исходник
    -- *.p   -> ожидаемое дерево парсера (в формате Show, приоритетный формат)
    -- *.ast -> legacy-формат (для обратной совместимости)
    -- Поддерживается вложенная структура директорий.
    forM_ fixtures assertFixtureByPath
    forM_ manifestCases assertManifestCase

    describe "приоритет операций (дерево Expr)" $ do
      it "умножение жёстче сложения: a+b*c → a+(b*c)" $
        parseMainReturn "int main(){ return a+b*c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpAdd
                (ExprVar "a")
                (ExprBinary OpMul (ExprVar "b") (ExprVar "c"))
            )

      it "умножение жёстче сложения слева: a*b+c → (a*b)+c" $
        parseMainReturn "int main(){ return a*b+c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpAdd
                (ExprBinary OpMul (ExprVar "a") (ExprVar "b"))
                (ExprVar "c")
            )

      it "сложение левоассоциативно: a-b-c → (a-b)-c" $
        parseMainReturn "int main(){ return a-b-c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpSub
                (ExprBinary OpSub (ExprVar "a") (ExprVar "b"))
                (ExprVar "c")
            )

      it "сдвиг слабее сложения: a<<b+c → a<<(b+c)" $
        parseMainReturn "int main(){ return a<<b+c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpShl
                (ExprVar "a")
                (ExprBinary OpAdd (ExprVar "b") (ExprVar "c"))
            )

      it "сложение жёстче равенства: a+b==c → (a+b)==c" $
        parseMainReturn "int main(){ return a+b==c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpEq
                (ExprBinary OpAdd (ExprVar "a") (ExprVar "b"))
                (ExprVar "c")
            )

      it "побитовое И жёстче ИЛИ: a|b&c → a|(b&c)" $
        parseMainReturn "int main(){ return a|b&c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpBitOr
                (ExprVar "a")
                (ExprBinary OpBitAnd (ExprVar "b") (ExprVar "c"))
            )

      it "побитовое XOR между И и ИЛИ: a^b|c → (a^b)|c" $
        parseMainReturn "int main(){ return a^b|c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpBitOr
                (ExprBinary OpBitXor (ExprVar "a") (ExprVar "b"))
                (ExprVar "c")
            )

      it "логическое И жёстче ИЛИ: a||b&&c → a||(b&&c)" $
        parseMainReturn "int main(){ return a||b&&c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpOr
                (ExprVar "a")
                (ExprBinary OpAnd (ExprVar "b") (ExprVar "c"))
            )

      it "скобки переопределяют приоритет: (a+b)*c" $
        parseMainReturn "int main(){ return (a+b)*c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpMul
                (ExprBinary OpAdd (ExprVar "a") (ExprVar "b"))
                (ExprVar "c")
            )

      it "тернарный оператор правоассоциативен: a?b:c?d:e → a?b:(c?d:e)" $
        parseMainReturn "int main(){ return a?b:c?d:e; }\n"
          `shouldBe` Right
            ( ExprTernary
                (ExprVar "a")
                (ExprVar "b")
                ( ExprTernary
                    (ExprVar "c")
                    (ExprVar "d")
                    (ExprVar "e")
                )
            )

      it "присваивание правоассоциативно: a=b=c" $
        parseMainReturn "int main(){ return a=b=c; }\n"
          `shouldBe` Right
            ( ExprAssign
                AAssign
                (ExprVar "a")
                (ExprAssign AAssign (ExprVar "b") (ExprVar "c"))
            )

      it "композиция: отношение и равенство — a<b==c → (a<b)==c" $
        parseMainReturn "int main(){ return a<b==c; }\n"
          `shouldBe` Right
            ( ExprBinary
                OpEq
                (ExprBinary OpLt (ExprVar "a") (ExprVar "b"))
                (ExprVar "c")
            )

    it "возвращает AstUnknown для неподдерживаемого паттерна токенов" $
      parseTokens [TokenInt, TokenIdentifier "x"] `shouldBe` AstUnknown [TokenInt, TokenIdentifier "x"]

discoverParserFixtures :: IO [FilePath]
discoverParserFixtures = do
  cFiles <- findFilesByExtension "tests/src_c" ".c"
  paired <- filterM hasParserExpectation cFiles
  pure (sort paired)
  where
    hasParserExpectation cFile = do
      hasP <- doesFileExist (replaceExtension cFile ".p")
      hasAst <- doesFileExist (replaceExtension cFile ".ast")
      pure (hasP || hasAst)

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

assertFixtureByPath :: FilePath -> Spec
assertFixtureByPath cFile =
  it ("парсит fixture " ++ cFile) $ do
    source <- readFile cFile
    expectationFile <- parserExpectationFile cFile
    expectedAst <- readFile expectationFile
    let actualAst = parseTokens (lexer source)
    show actualAst `shouldBe` trim expectedAst
  where
    parserExpectationFile filePath = do
      let pFile = replaceExtension filePath ".p"
      hasP <- doesFileExist pFile
      pure $
        if hasP
          then pFile
          else replaceExtension filePath ".ast"

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

dropWhileEnd :: (Char -> Bool) -> String -> String
dropWhileEnd predicate = reverse . dropWhile predicate . reverse

-- | Разобрать минимальную программу с одним return и вернуть выражение (для проверки дерева).
parseMainReturn :: String -> Either String Expr
parseMainReturn raw =
  let src = preprocess raw
   in case parseTokens (lexer src) of
        AstProgram [AstFunctionDef "main" _ _ (AstCompound [AstReturn (Just e)])] -> Right e
        x -> Left ("ожидался main с одним return, получено: " ++ show x)

assertManifestCase :: ManifestCase -> Spec
assertManifestCase mc =
  it ("manifest: " ++ mcName mc) $ do
    source <- readFile (mcInputFile mc)
    expectedAst <- readFile (mcOutputFile mc)
    let actual = show (parseTokens (lexer source))
    case matchTextExpectation (mcExpectation mc) actual (trim expectedAst) of
      Right matched -> matched `shouldBe` True
      Left err -> expectationFailure err
