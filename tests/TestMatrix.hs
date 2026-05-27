{-# LANGUAGE OverloadedStrings #-}

-- | Запись фактов прогона тестов в JSON (точка правды для markdown-таблицы).
module TestMatrix
  ( MatrixStatus (..),
    MatrixEntry (..),
    TestMatrixDoc (..),
    initMatrix,
    resolveMatrixPath,
    recordEntry,
    recordCompare,
    shouldBeRecorded,
    shouldBeTextRecorded,
    recordPending,
    flushMatrix,
  )
where

import Data.Aeson (ToJSON (..), encode, object, (.=))
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BL
import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef)
import System.Directory (createDirectoryIfMissing)
import System.Environment (lookupEnv)
import System.FilePath (takeDirectory)
import GHC.IO (unsafePerformIO)
import Test.Hspec (shouldBe)

import TestManifest (loadMatrixPath)

data MatrixStatus
  = Pass
  | Fail
  | Pending
  deriving (Eq, Show)

instance ToJSON MatrixStatus where
  toJSON Pass = A.String "pass"
  toJSON Fail = A.String "fail"
  toJSON Pending = A.String "pending"

data MatrixEntry = MatrixEntry
  { meSuite :: !String,
    meName :: !String,
    meInput :: !String,
    meExpected :: !String,
    meActual :: !String,
    meStatus :: !MatrixStatus,
    meNote :: !String
  }
  deriving (Eq, Show)

instance ToJSON MatrixEntry where
  toJSON e =
    object
      [ "suite" .= meSuite e,
        "name" .= meName e,
        "input" .= meInput e,
        "expected" .= meExpected e,
        "actual" .= meActual e,
        "status" .= meStatus e,
        "note" .= meNote e
      ]

data TestMatrixDoc = TestMatrixDoc
  { tmdMatrixPath :: !FilePath,
    tmdManifestPath :: !(Maybe FilePath),
    tmdGeneratedAt :: !String,
    tmdEntries :: ![MatrixEntry]
  }
  deriving (Eq, Show)

instance ToJSON TestMatrixDoc where
  toJSON doc =
    object
      [ "matrixPath" .= tmdMatrixPath doc,
        "manifestPath" .= tmdManifestPath doc,
        "generatedAt" .= tmdGeneratedAt doc,
        "entries" .= tmdEntries doc
      ]

matrixRef :: IORef (Maybe FilePath, [MatrixEntry])
matrixRef = unsafeGlobalMatrixRef
  where
    -- Глобальный буфер на один прогон test-web-report (hspec sequential).
    unsafeGlobalMatrixRef =
      unsafePerformIO (newIORef (Nothing, []))
{-# NOINLINE matrixRef #-}

resolveGeneratedAt :: IO String
resolveGeneratedAt = do
  envUtc <- lookupEnv "SOURCE_DATE_EPOCH"
  case envUtc of
    Just sec | not (null sec) -> pure sec
    _ -> do
      envIso <- lookupEnv "TEST_MATRIX_TIMESTAMP"
      pure (maybe "" id envIso)

resolveMatrixPath :: IO FilePath
resolveMatrixPath = do
  envMatrix <- lookupEnv "TEST_MATRIX"
  case envMatrix of
    Just path | not (null path) -> pure path
    _ -> do
      envManifest <- lookupEnv "TEST_MANIFEST"
      let manifestPath =
            case envManifest of
              Just p | not (null p) -> p
              _ -> "tests/test-manifest.json"
      loadMatrixPath manifestPath

initMatrix :: IO ()
initMatrix = do
  path <- resolveMatrixPath
  atomicModifyIORef' matrixRef (\_ -> ((Just path, []), ()))

recordEntry :: MatrixEntry -> IO ()
recordEntry entry = do
  atomicModifyIORef' matrixRef (\(path, xs) -> ((path, xs ++ [entry]), ()))
  -- Сбрасываем после каждой записи: defaultMain завершает процесс через exitWith.
  flushMatrix

recordCompare :: String -> String -> String -> String -> String -> IO ()
recordCompare suite name input expected actual =
  recordEntry
    MatrixEntry
      { meSuite = suite,
        meName = name,
        meInput = input,
        meExpected = expected,
        meActual = actual,
        meStatus = if expected == actual then Pass else Fail,
        meNote = ""
      }

recordPending :: String -> String -> String -> String -> IO ()
recordPending suite name input note =
  recordEntry
    MatrixEntry
      { meSuite = suite,
        meName = name,
        meInput = input,
        meExpected = "TODO",
        meActual = "—",
        meStatus = Pending,
        meNote = note
      }

-- | Записать факт и выполнить shouldBe (ожидаемое значение первым, фактическое — вычисленное).
shouldBeRecorded :: (Eq a, Show a) => String -> String -> String -> a -> a -> IO ()
shouldBeRecorded suite name input expected actual = do
  recordCompare suite name input (show expected) (show actual)
  actual `shouldBe` expected

-- | IO-действие, результат сравнивается как текст (preprocess и т.п.).
shouldBeTextRecorded :: String -> String -> String -> String -> IO String -> IO ()
shouldBeTextRecorded suite name input expected action = do
  actual <- action
  recordCompare suite name input expected actual
  actual `shouldBe` expected

flushMatrix :: IO ()
flushMatrix = do
  (maybePath, entries) <- readIORef matrixRef
  case maybePath of
    Nothing -> pure ()
    Just path -> do
      generatedAt <- resolveGeneratedAt
      manifestPath <- lookupEnv "TEST_MANIFEST"
      let doc =
            TestMatrixDoc
              { tmdMatrixPath = path,
                tmdManifestPath = manifestPath,
                tmdGeneratedAt = generatedAt,
                tmdEntries = entries
              }
      createDirectoryIfMissing True (takeDirectory path)
      BL.writeFile path (encode doc)
      atomicModifyIORef' matrixRef (\_ -> ((Just path, entries), ()))
