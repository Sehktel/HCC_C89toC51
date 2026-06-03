import Lexer (lexerPure)

main :: IO ()
main = do
  putStrLn "return:"
  print (lexerPure "return ((unsigned int)high_byte << 8) | low_byte;")
  putStrLn "clear:"
  print (lexerPure "((test_byte) &= (~(1 << (0))));")
  putStrLn "read:"
  print (lexerPure "if (((test_byte) & (1 << (1)))) result |= 0x01;")
  putStrLn "toggle no inner:"
  print (lexerPure "((test_byte) ^= (1 << (1)));")
