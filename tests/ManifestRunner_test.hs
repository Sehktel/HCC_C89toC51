module ManifestRunner_test (manifestRunnerSpec) where

import Lexer (lexer)
import Parser (parseTokens)
import System.Environment (lookupEnv)
import Test.Hspec (Spec, describe, expectationFailure, it, runIO, shouldBe)
import TestManifest (ManifestCase (..), loadAllCases, matchTextExpectation)

manifestRunnerSpec :: Spec
manifestRunnerSpec = do
  manifestPath <- runIO resolveManifestPath
  cases <- runIO (loadAllCases manifestPath)
  describe "Manifest runner" $ do
    it ("использует манифест: " ++ manifestPath) $
      (null cases) `shouldBe` False
    mapM_ assertManifestCase cases

resolveManifestPath :: IO FilePath
resolveManifestPath = do
  maybePath <- lookupEnv "TEST_MANIFEST"
  pure $
    case maybePath of
      Just path | not (null path) -> path
      _ -> "tests/test-manifest.json"

assertManifestCase :: ManifestCase -> Spec
assertManifestCase mc =
  it ("manifest: " ++ mcName mc ++ " [" ++ mcPackage mc ++ "]") $ do
    source <- readFile (mcInputFile mc)
    expected <- readFile (mcOutputFile mc)
    case mcPackage mc of
      "Lexer" -> do
        let actual = show (lexer source)
        assertTextExpectation mc actual expected
      "Parser" -> do
        let actual = show (parseTokens (lexer source))
        assertTextExpectation mc actual expected
      other ->
        expectationFailure ("Неизвестный package в манифесте: " ++ other)

assertTextExpectation :: ManifestCase -> String -> String -> IO ()
assertTextExpectation mc actual expected =
  case matchTextExpectation (mcExpectation mc) actual (trim expected) of
    Right matched -> matched `shouldBe` True
    Left err -> expectationFailure err

trim :: String -> String
trim = dropWhile isSpaceLike . dropWhileEndSpace

dropWhileEndSpace :: String -> String
dropWhileEndSpace = reverse . dropWhile isSpaceLike . reverse

isSpaceLike :: Char -> Bool
isSpaceLike ch = ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t'
