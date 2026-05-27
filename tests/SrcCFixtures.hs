{-# LANGUAGE OverloadedStrings #-}

-- | Общий обход tests/src_c: .c + эталоны с тем же stem (.l, .p, .pp, .ir).
module SrcCFixtures
  ( srcCRoot,
    goldenLexerExt,
    goldenParserExt,
    goldenParserLegacyExt,
    goldenPreprocessorExt,
    goldenIrExt,
    goldenHirExt,
    goldenMirExt,
    goldenLirExt,
    srcCPreprocessConfig,
    findCFiles,
    findCFilesUnder,
    discoverWithGolden,
    discoverLexerFixtures,
    discoverParserFixtures,
    discoverPreprocessorFixtures,
    discoverIrFixtures,
    discoverHirFixtures,
    discoverMirFixtures,
    discoverLirFixtures,
    trim,
    dropWhileEnd,
  )
where

import Control.Monad (filterM)
import Data.Char (isSpace)
import Data.List (isPrefixOf, nub, sort)
import Preprocessor (PreprocessConfig (..), defaultPreprocessConfig)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath ((</>), normalise, replaceExtension, takeExtension, addTrailingPathSeparator)

srcCRoot :: FilePath
srcCRoot = "tests/src_c"

goldenLexerExt, goldenParserExt, goldenParserLegacyExt, goldenPreprocessorExt, goldenIrExt, goldenHirExt, goldenMirExt, goldenLirExt :: String
goldenLexerExt = ".l"
goldenParserExt = ".p"
goldenParserLegacyExt = ".ast"
goldenPreprocessorExt = ".pp"
goldenIrExt = ".ir"
goldenHirExt = ".hir"
goldenMirExt = ".mir"
goldenLirExt = ".lir"

-- | Каталоги для @#include \<...\>@ в фикстурах src_c.
srcCPreprocessConfig :: PreprocessConfig
srcCPreprocessConfig =
  defaultPreprocessConfig
    { pcAngleIncludeDirs =
        [ srcCRoot </> "c_base",
          srcCRoot </> "c_code",
          srcCRoot </> "c_adv" </> "_headers",
          srcCRoot </> "examples" </> "include"
        ],
      pcQuoteIncludeDirs = [srcCRoot </> "c_adv" </> "_headers"]
    }

findCFiles :: IO [FilePath]
findCFiles = sort <$> findFilesByExtension srcCRoot ".c"

findCFilesUnder :: [FilePath] -> IO [FilePath]
findCFilesUnder prefixes = do
  allC <- findCFiles
  let normPrefixes = map (normalise . (srcCRoot </>)) prefixes
  pure (sort (filter (anyUnder normPrefixes) allC))
  where
    anyUnder ps path =
      let np = normalise path
       in any (isUnder np) ps
    isUnder file prefix =
      let p = addTrailingPathSeparator (normalise prefix)
       in p `isPrefixOf` file || normalise prefix == file

discoverWithGolden :: String -> IO [FilePath]
discoverWithGolden ext = do
  cFiles <- findCFiles
  paired <- filterM (\c -> doesFileExist (replaceExtension c ext)) cFiles
  pure (sort (nub paired))

discoverLexerFixtures :: IO [FilePath]
discoverLexerFixtures = discoverWithGolden goldenLexerExt

discoverParserFixtures :: IO [FilePath]
discoverParserFixtures = do
  cFiles <- findCFiles
  paired <- filterM hasParserExpectation cFiles
  pure (sort paired)
  where
    hasParserExpectation cFile = do
      hasP <- doesFileExist (replaceExtension cFile goldenParserExt)
      hasAst <- doesFileExist (replaceExtension cFile goldenParserLegacyExt)
      pure (hasP || hasAst)

discoverPreprocessorFixtures :: IO [FilePath]
discoverPreprocessorFixtures = discoverWithGolden goldenPreprocessorExt

discoverIrFixtures :: IO [FilePath]
discoverIrFixtures = discoverWithGolden goldenIrExt

discoverHirFixtures :: IO [FilePath]
discoverHirFixtures = discoverWithGolden goldenHirExt

discoverMirFixtures :: IO [FilePath]
discoverMirFixtures = discoverWithGolden goldenMirExt

discoverLirFixtures :: IO [FilePath]
discoverLirFixtures = discoverWithGolden goldenLirExt

findFilesByExtension :: FilePath -> String -> IO [FilePath]
findFilesByExtension root extension = do
  exists <- doesDirectoryExist root
  if not exists
    then pure []
    else go root
  where
    go dir = do
      names <- listDirectory dir
      nested <- mapM goDir names
      pure (concat nested)
      where
        goDir name = do
          let path = dir </> name
          isDir <- doesDirectoryExist path
          if isDir
            then go path
            else pure [path | takeExtension path == extension]

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

dropWhileEnd :: (Char -> Bool) -> String -> String
dropWhileEnd predicate = reverse . dropWhile predicate . reverse
