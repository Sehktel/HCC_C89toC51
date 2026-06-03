import Data.List (isPrefixOf, tails)
import Lexer (lexerPure)

-- | Ищет подстроку в строке токенов.
findSubstring :: String -> String -> Maybe Int
findSubstring nd s = go 0
  where
    go i
      | nd `isPrefixOf` drop i s = Just i
      | i >= length s = Nothing
      | otherwise = go (i + 1)

countInfix :: String -> String -> Int
countInfix nd str = length $ filter (nd `isPrefixOf`) (tails str)

-- | Отладка READ_BIT: где result|= и сколько if (((test_byte)...
main :: IO ()
main = do
  let base = "tests/src_c/c_adv/test_bit_operations/test_bit_operations"
  pp <- readFile (base ++ ".pp")
  l <- readFile (base ++ ".l")
  let act = show (lexerPure pp)
      exp = filter (`notElem` ['\r', '\n']) l
      needle = "TokenIdentifier \"result\",TokenPipeEqual"
      readPat = "TokenIf,TokenLeftParen,TokenLeftParen,TokenLeftParen,TokenIdentifier \"test_byte\""
  case findSubstring needle act of
    Just i -> do
      putStrLn $ "first result|= at index " ++ show i
      putStrLn "=== act (120 chars before) ==="
      putStrLn $ take 120 (drop (max 0 (i - 120)) act)
      putStrLn "=== exp (120 chars before) ==="
      putStrLn $ take 120 (drop (max 0 (i - 120)) exp)
    Nothing -> putStrLn "needle not found in act"
  putStrLn $ "READ if count in act: " ++ show (countInfix readPat act)
