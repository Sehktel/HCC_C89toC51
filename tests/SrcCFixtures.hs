{-# LANGUAGE OverloadedStrings #-}

-- | Общий обход tests/src_c: .c + эталоны с тем же stem (.l, .p, .pp, .ir).
module SrcCFixtures
  ( srcCRoot,
    goldenLexerExt,
    goldenParserExt,
    goldenParserLegacyExt,
    goldenPreprocessorExt,
    goldenIrExt,
    findCFiles,
    discoverWithGolden,
    discoverLexerFixtures,
    discoverParserFixtures,
    discoverPreprocessorFixtures,
    discoverIrFixtures,
    trim,
    dropWhileEnd,
  )
where

import Control.Monad (filterM)
import Data.Char (isSpace)
import Data.List (nub, sort)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath ((</>), replaceExtension, takeExtension)

srcCRoot :: FilePath
srcCRoot = "tests/src_c"

goldenLexerExt, goldenParserExt, goldenParserLegacyExt, goldenPreprocessorExt, goldenIrExt :: String
goldenLexerExt = ".l"
goldenParserExt = ".p"
goldenParserLegacyExt = ".ast"
goldenPreprocessorExt = ".pp"
goldenIrExt = ".ir"

findCFiles :: IO [FilePath]
findCFiles = sort <$> findFilesByExtension srcCRoot ".c"

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
