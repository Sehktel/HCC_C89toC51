{-# LANGUAGE OverloadedStrings #-}

module TestManifest
  ( Manifest (..),
    Expectation (..),
    ManifestCase (..),
    loadManifest,
    loadAllCases,
    loadCasesByPackage,
    loadReportPath,
    matchTextExpectation,
  )
where

import Data.Aeson (FromJSON (..), eitherDecodeFileStrict', withObject, (.:))
import Data.List (isInfixOf, sort)
import Data.List (filter)
import Prelude hiding (filter)

data Manifest = Manifest
  { mReportPath :: FilePath,
    mCases :: [ManifestCase]
  }
  deriving (Eq, Show)

data Expectation
  = ShouldBe
  | ShouldSatisfy
  | ShouldStartWith
  | ShouldEndWith
  | ShouldContain
  | ShouldMatchList
  | ShouldNotBe
  | ShouldNotSatisfy
  | ShouldNotContain
  | ShouldReturn
  | ShouldNotReturn
  | ShouldThrow
  | ExpectationFailure
  deriving (Eq, Show)

data ManifestCase = ManifestCase
  { mcName :: String,
    mcPackage :: String,
    mcInputFile :: FilePath,
    mcOutputFile :: FilePath,
    mcExpectation :: Expectation
  }
  deriving (Eq, Show)

instance FromJSON Manifest where
  parseJSON =
    withObject "Manifest" $ \obj ->
      Manifest
        <$> obj .: "reportPath"
        <*> obj .: "cases"

instance FromJSON Expectation where
  parseJSON rawValue = do
    raw <- parseJSON rawValue
    case raw :: String of
      "shouldBe" -> pure ShouldBe
      "shouldSatisfy" -> pure ShouldSatisfy
      "shouldStartWith" -> pure ShouldStartWith
      "shouldEndWith" -> pure ShouldEndWith
      "shouldContain" -> pure ShouldContain
      "shouldMatchList" -> pure ShouldMatchList
      "shouldNotBe" -> pure ShouldNotBe
      "shouldNotSatisfy" -> pure ShouldNotSatisfy
      "shouldNotContain" -> pure ShouldNotContain
      "shouldReturn" -> pure ShouldReturn
      "shouldNotReturn" -> pure ShouldNotReturn
      "shouldThrow" -> pure ShouldThrow
      "expectationFailure" -> pure ExpectationFailure
      other -> fail ("Unsupported expectation in manifest: " ++ other)

instance FromJSON ManifestCase where
  parseJSON =
    withObject "ManifestCase" $ \obj ->
      ManifestCase
        <$> obj .: "name"
        <*> obj .: "package"
        <*> obj .: "inputFile"
        <*> obj .: "outputFile"
        <*> obj .: "expectation"

loadManifest :: FilePath -> IO Manifest
loadManifest manifestPath = do
  decoded <- eitherDecodeFileStrict' manifestPath
  case decoded of
    Left err ->
      ioError (userError ("Manifest JSON decode error in " ++ manifestPath ++ ": " ++ err))
    Right manifest ->
      pure (manifest :: Manifest)

loadCasesByPackage :: FilePath -> String -> IO [ManifestCase]
loadCasesByPackage manifestPath targetPackage = do
  allCases <- loadAllCases manifestPath
  pure (filter (\mc -> mcPackage mc == targetPackage) allCases)

loadAllCases :: FilePath -> IO [ManifestCase]
loadAllCases manifestPath = mCases <$> loadManifest manifestPath

loadReportPath :: FilePath -> IO FilePath
loadReportPath manifestPath = mReportPath <$> loadManifest manifestPath

-- Сравнение текстовых результатов (show-выводы, содержимое файлов и т.д.).
matchTextExpectation :: Expectation -> String -> String -> Either String Bool
matchTextExpectation expectation actual expected =
  case expectation of
    ShouldBe -> Right (actual == expected)
    ShouldSatisfy -> Right (actual == expected)
    ShouldStartWith -> Right (expected `isPrefixOfText` actual)
    ShouldEndWith -> Right (expected `isSuffixOfText` actual)
    ShouldContain -> Right (expected `isInfixOf` actual)
    ShouldMatchList -> Right (normalizeLines actual == normalizeLines expected)
    ShouldNotBe -> Right (actual /= expected)
    ShouldNotSatisfy -> Right (actual /= expected)
    ShouldNotContain -> Right (not (expected `isInfixOf` actual))
    ShouldReturn ->
      Left "Expectation shouldReturn поддерживается только в IO-раннерах"
    ShouldNotReturn ->
      Left "Expectation shouldNotReturn поддерживается только в IO-раннерах"
    ShouldThrow ->
      Left "Expectation shouldThrow поддерживается только в exception-раннерах"
    ExpectationFailure ->
      Left "Expectation expectationFailure требует явного failure-сценария"

isPrefixOfText :: String -> String -> Bool
isPrefixOfText prefix value = take (length prefix) value == prefix

isSuffixOfText :: String -> String -> Bool
isSuffixOfText suffix value =
  let suffixLen = length suffix
      valueLen = length value
   in suffixLen <= valueLen && drop (valueLen - suffixLen) value == suffix

normalizeLines :: String -> [String]
normalizeLines =
  sort . filter (not . null) . map trimLine . lines

trimLine :: String -> String
trimLine = dropWhile (== ' ') . dropWhileEndSpace

dropWhileEndSpace :: String -> String
dropWhileEndSpace = reverse . dropWhile (== ' ') . reverse
