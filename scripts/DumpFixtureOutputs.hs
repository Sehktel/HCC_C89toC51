{-# LANGUAGE OverloadedStrings #-}

-- | Печатает JSON: { "tests/src_c/.../file.c": { "lexer": "...", "parser": "..." } }
module Main (main) where

import Control.Monad (filterM)
import Data.Aeson (Value (..), object, (.=))
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BL
import Data.List (sort)
import Lexer (lexer, lexerPure)
import Logger (Logger, silentLogger)
import Parser (parseTokens)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath ((</>), replaceExtension, takeExtension)

main :: IO ()
main = do
  cFiles <- sort <$> findFilesByExtension "tests/src_c" ".c"
  let lg = silentLogger
  entries <- mapM (dumpOne lg) cFiles
  BL.putStrLn (A.encode (object entries))

dumpOne :: Logger -> FilePath -> IO (String, Value)
dumpOne lg cFile = do
  src <- readFile cFile
  hasLFile <- doesFileExist (replaceExtension cFile ".l")
  hasP <- doesFileExist (replaceExtension cFile ".p")
  hasAst <- doesFileExist (replaceExtension cFile ".ast")
  let lexerVal =
        if hasLFile
          then Just (show (lexerPure src))
          else Nothing
  parserVal <-
    if hasP || hasAst
      then do
        toks <- lexer lg src
        ast <- parseTokens lg toks
        pure (Just (show ast))
      else pure Nothing
  pure
    ( cFile,
      object
        ( [ "lexer" .= v | Just v <- [lexerVal]
          ]
            ++ [ "parser" .= v | Just v <- [parserVal]
               ]
        )
    )

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
