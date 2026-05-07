{-# LANGUAGE OverloadedStrings #-}

module TestManifest
  ( Manifest (..),
    Expectation (..),
    ManifestCase (..),
    ProcessSpec (..),
    loadManifest,
    loadAllCases,
    loadCasesByPackage,
    loadReportPath,
    matchTextExpectation,
    matchExitCodeExpectation,
  )
where

import Data.Aeson (FromJSON (..), eitherDecodeFileStrict', withObject, (.:))
import qualified Data.Aeson.Types as AesonTypes
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
  | ExitCodeShouldBe Int
  deriving (Eq, Show)

data ProcessSpec = ProcessSpec
  { psCommand :: String,
    psArgs :: [String]
  }
  deriving (Eq, Show)

data ManifestCase = ManifestCase
  { mcName :: String,
    mcPackage :: String,
    mcInputFile :: FilePath,
    mcOutputFile :: FilePath,
    mcExpectation :: Expectation,
    mcProcess :: Maybe ProcessSpec
  }
  deriving (Eq, Show)

instance FromJSON Manifest where
  parseJSON =
    withObject "Manifest" $ \obj ->
      Manifest
        <$> obj .: "reportPath"
        <*> obj .: "cases"

instance FromJSON Expectation where
  parseJSON value =
    parseFromString value <> parseFromObject value
    where
      parseFromString rawValue = do
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

      parseFromObject =
        withObject "Expectation" $ \obj -> do
          kind <- obj .: "kind" :: AesonTypes.Parser String
          case kind of
            "exitCodeShouldBe" -> ExitCodeShouldBe <$> obj .: "value"
            other -> fail ("Unsupported expectation object kind: " ++ other)

instance FromJSON ProcessSpec where
  parseJSON =
    withObject "ProcessSpec" $ \obj ->
      ProcessSpec
        <$> obj .: "command"
        <*> obj .: "args"

instance FromJSON ManifestCase where
  parseJSON =
    withObject "ManifestCase" $ \obj ->
      ManifestCase
        <$> obj .: "name"
        <*> obj .: "package"
        <*> obj .: "inputFile"
        <*> obj .: "outputFile"
        <*> obj .: "expectation"
        <*> obj .: "process"

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
    ExitCodeShouldBe _ ->
      Left "Expectation exitCodeShouldBe нельзя применять к текстовому сравнению"

-- Сравнение кодов завершения для сценариев запуска внешних команд.
matchExitCodeExpectation :: Expectation -> Int -> Either String Bool
matchExitCodeExpectation expectation exitCode =
  case expectation of
    ExitCodeShouldBe expectedCode -> Right (exitCode == expectedCode)
    _ -> Left "Текущий expectation не поддерживает сравнение exit code"

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
