{-# LANGUAGE OverloadedStrings #-}
import Control.Monad (filterM)
import Data.Char (isSpace)
import Data.List (dropWhile, dropWhileEnd)
import Lexer (lexerPure)
import System.Directory (doesFileExist, listDirectory)
import System.FilePath ((</>), normalise, replaceExtension, takeDirectory, takeFileName)

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

checkOne :: FilePath -> IO ()
checkOne ppFile = do
  let base = replaceExtension ppFile ""
      lFile = base ++ ".l"
  pp <- readFile ppFile
  l <- trim <$> readFile lFile
  let act = show (lexerPure pp)
  if act == l
    then putStrLn $ "OK  " ++ takeFileName base
    else do
      let diffs = [(i, act !! i, l !! i) | i <- [0 .. min (length act) (length l) - 1], act !! i /= l !! i]
      let i = case diffs of ((x, _, _) : _) -> x; [] -> min (length act) (length l)
      putStrLn $ "FAIL " ++ takeFileName base ++ " (act=" ++ show (length act) ++ " exp=" ++ show (length l) ++ ") @=" ++ show i
      putStrLn $ "  act: ..." ++ take 120 (drop (max 0 (i - 40)) act) ++ "..."
      putStrLn $ "  exp: ..." ++ take 120 (drop (max 0 (i - 40)) l) ++ "..."

main :: IO ()
main = do
  let root = normalise "tests/src_c/c_adv"
  dirs <- listDirectory root
  mapM_ checkOne =<< filterM doesFileExist [root </> d </> takeFileName d ++ ".pp" | d <- dirs, d /= "_headers"]
