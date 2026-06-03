import Data.Char (isSpace)
import Data.List (dropWhile, dropWhileEnd)
import Lexer (lexerPure)

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

-- | Сравнивает lexerPure(.pp) с golden .l; печатает первое расхождение.
main :: IO ()
main = do
  let bases =
        [ "tests/src_c/c_adv/test_timer_operations/test_timer_operations"
        , "tests/src_c/c_adv/test_bit_operations/test_bit_operations"
        , "tests/src_c/c_adv/test_port_operations/test_port_operations"
        , "tests/src_c/c_adv/test_memory_types/test_memory_types"
        , "tests/src_c/c_adv/test_interrupt_setup/test_interrupt_setup"
        , "tests/src_c/c_adv/main_test/main_test"
        ]
  mapM_ inspect bases

inspect :: FilePath -> IO ()
inspect base = do
  pp <- readFile (base ++ ".pp")
  l <- trim <$> readFile (base ++ ".l")
  let act = show (lexerPure pp)
      diffs = [i | i <- [0 .. min (length act) (length l) - 1], act !! i /= l !! i]
  putStrLn $ "\n=== " ++ base ++ " ==="
  case diffs of
    [] -> putStrLn $ "MATCH  actLen=" ++ show (length act)
    (idx : _) -> do
      putStrLn $ "FAIL @" ++ show idx ++ "  actLen=" ++ show (length act) ++ " expLen=" ++ show (length l)
      putStrLn $ "act: " ++ take 80 (drop (max 0 (idx - 40)) act)
      putStrLn $ "exp: " ++ take 80 (drop (max 0 (idx - 40)) l)
