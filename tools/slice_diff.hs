import Data.Char (isSpace)
import Data.List (dropWhile, dropWhileEnd)
import Lexer (lexerPure)
import System.Environment (getArgs)

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

-- | Печатает фрагмент act/exp вокруг индекса расхождения.
sliceAt :: Int -> String -> String
sliceAt i s = take 160 (drop (max 0 (i - 60)) s)

main :: IO ()
main = do
  [base, idxStr] <- getArgs
  let i = read idxStr :: Int
  pp <- readFile (base ++ ".pp")
  l <- trim <$> readFile (base ++ ".l")
  let act = show (lexerPure pp)
  putStrLn $ "act len=" ++ show (length act) ++ "  exp len=" ++ show (length l)
  putStrLn $ "act: " ++ sliceAt i act
  putStrLn $ "exp: " ++ sliceAt i l
