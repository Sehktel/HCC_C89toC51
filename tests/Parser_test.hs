module Parser_test (parserSpec) where

import Control.Monad (filterM, forM, forM_)
import Data.Char (isSpace)
import Data.List (sort)
import Lexer (Token (..), lexer)
import Parser (Ast (..), parseTokens)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath ((</>), replaceExtension, takeExtension)
import Test.Hspec (Spec, describe, expectationFailure, it, runIO, shouldBe)
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

assertManifestCase :: ManifestCase -> Spec
assertManifestCase mc =
  it ("manifest: " ++ mcName mc) $ do
    source <- readFile (mcInputFile mc)
    expectedAst <- readFile (mcOutputFile mc)
    let actual = show (parseTokens (lexer source))
    case matchTextExpectation (mcExpectation mc) actual (trim expectedAst) of
      Right matched -> matched `shouldBe` True
      Left err -> expectationFailure err
