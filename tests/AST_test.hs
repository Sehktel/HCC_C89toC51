module AST_test (astSpec) where

import AST
  ( AST (..),
    AssignOp (..),
    C51MemoryClass (..),
    Decl (..),
    DeclSuffix (..),
    DeclSpecifier (..),
    ExternalDecl (..),
    FunctionDef (..),
    Program (..),
    Stmt (..),
    TypeSpec (..),
    fromParserAst,
    parseDeclFromTokens,
  )
import qualified AST as Sem
import Lexer (Token (..), lexer)
import Logger (silentLogger)
import Parser (Ast (..), parseTokens)
import qualified Parser as Syn
import Preprocessor (defaultPreprocessConfig, preprocess)
import Test.Hspec (Spec, describe, expectationFailure, it, shouldBe)
import TestMatrix (MatrixEntry (..), MatrixStatus (..), recordEntry, shouldBeRecorded)

declShouldBe :: String -> String -> [Token] -> Decl -> IO ()
declShouldBe name inp toks expected = do
  case parseDeclFromTokens toks of
    Right actual -> shouldBeRecorded "AST" name inp expected actual
    Left err -> expectationFailure ("parseDeclFromTokens: " ++ show err)

-- | Полный фронтенд: preprocess → lexer → parser → семантический AST.
parseSemanticAst :: String -> IO AST
parseSemanticAst src = do
  let lg = silentLogger
  normalized <- preprocess defaultPreprocessConfig Nothing src
  toks <- lexer lg normalized
  syn <- parseTokens lg toks
  pure (fromParserAst syn)

-- | Разбор декларации из исходника (локальный контекст: внутри функции).
parseLocalDecl :: String -> IO Stmt
parseLocalDecl src = do
  ast <- parseSemanticAst ("int main(void) { " ++ src ++ " return 0; }\n")
  case ast of
    ASTProgram (Program [ExtFunction (FunctionDef _ _ _ (SCompound stmts))]) ->
      case stmts of
        (decl : _) -> pure decl
        _ -> error "expected declaration in compound"
    other -> error ("expected program with main, got: " ++ show other)

astSpec :: Spec
astSpec = do
  describe "Pipeline -> Parser.Ast (синтаксис)" $ do
    it "строит синтаксическое дерево после preprocess + lexer + parser" $ do
      let src = "  int main() {  \n return 7; \n}\n"
          lg = silentLogger
      normalized <- preprocess defaultPreprocessConfig Nothing src
      toks <- lexer lg normalized
      ast <- parseTokens lg toks
      let expected =
            AstProgram
              [ AstFunctionDef
                  "main"
                  [TokenInt]
                  []
                  (AstCompound [AstReturn (Just (Syn.ExprLitInt 7))])
              ]
      shouldBeRecorded "AST (syntax)" "preprocess+lexer+parser main/7" src expected ast

    it "на неполном потоке токенов возвращает AstUnknown" $ do
      let lg = silentLogger
          toks = [TokenInt, TokenIdentifier "x"]
      ast <- parseTokens lg toks
      let expected = AstUnknown toks
      shouldBeRecorded "AST (syntax)" "AstUnknown" (show toks) expected ast

    it "принимает глобальную декларацию int x;" $ do
      let lg = silentLogger
          inp = "int x;"
      pp <- preprocess defaultPreprocessConfig Nothing inp
      toks <- lexer lg pp
      ast <- parseTokens lg toks
      let expected = AstProgram [AstDeclaration [TokenInt, TokenIdentifier "x", TokenSemicolon]]
      shouldBeRecorded "AST (syntax)" "глобальный int x;" inp expected ast

  describe "parseDeclFromTokens (итерация 2)" $ do
    it "int x;" $ do
      declShouldBe "int x;" (show [TokenInt, TokenIdentifier "x", TokenSemicolon]) [TokenInt, TokenIdentifier "x", TokenSemicolon] (Decl [SpecType TyInt] [Sem.Declarator "x" [] Nothing])

    it "unsigned char buf[10];" $ do
      let toks =
            [ TokenUnsigned,
              TokenChar,
              TokenIdentifier "buf",
              TokenLeftBracket,
              TokenNumber 10,
              TokenRightBracket,
              TokenSemicolon
            ]
      declShouldBe "unsigned char buf[10];" (show toks) toks (Decl [SpecType TyUnsigned, SpecType TyChar] [Sem.Declarator "buf" [DtorArray (Just (Sem.ELitInt 10))] Nothing])

    it "data int cnt;" $ do
      let toks = [TokenData, TokenInt, TokenIdentifier "cnt", TokenSemicolon]
      declShouldBe "data int cnt;" (show toks) toks (Decl [SpecC51Memory MemData, SpecType TyInt] [Sem.Declarator "cnt" [] Nothing])

    it "unsigned char x = 255;" $ do
      let toks =
            [ TokenUnsigned,
              TokenChar,
              TokenIdentifier "x",
              TokenAssign,
              TokenNumber 255,
              TokenSemicolon
            ]
      declShouldBe "unsigned char x = 255;" (show toks) toks (Decl [SpecType TyUnsigned, SpecType TyChar] [Sem.Declarator "x" [] (Just (Sem.ELitInt 255))])

    it "int a, b;" $ do
      let toks = [TokenInt, TokenIdentifier "a", TokenComma, TokenIdentifier "b", TokenSemicolon]
      declShouldBe "int a, b;" (show toks) toks (Decl [SpecType TyInt] [Sem.Declarator "a" [] Nothing, Sem.Declarator "b" [] Nothing])

    it "sfr P0 = 0x80;" $ do
      let toks =
            [ TokenSfr,
              TokenIdentifier "P0",
              TokenAssign,
              TokenNumber 0x80,
              TokenSemicolon
            ]
      declShouldBe "sfr P0 = 0x80;" (show toks) toks (Decl [SpecType TySfr] [Sem.Declarator "P0" [] (Just (Sem.ELitInt 0x80))])

  describe "fromParserAst (семантический подъём)" $ do
    it "поднимает main/return в ASTProgram" $ do
      let inp = "int main() { return 7; }\n"
      sem <- parseSemanticAst inp
      let expected =
            ASTProgram
              ( Program
                  [ ExtFunction
                      ( FunctionDef
                          "main"
                          [SpecType TyInt]
                          []
                          (SCompound [SReturn (Just (Sem.ELitInt 7))])
                      )
                  ]
              )
      shouldBeRecorded "AST (semantic)" "main/return 7" inp expected sem

    it "преобразует глобальный int x; в ASTProgram" $ do
      let inp = "int x;"
      sem <- parseSemanticAst inp
      let expected =
            ASTProgram
              ( Program
                  [ ExtDecl (Decl [SpecType TyInt] [Sem.Declarator "x" [] Nothing])]
              )
      shouldBeRecorded "AST (semantic)" "глобальный int x;" inp expected sem

    it "не ломает единицу трансляции со struct на уровне файла" $ do
      let inp = "struct S { int x; };\nint main(void) { return 0; }\n"
      sem <- parseSemanticAst inp
      case sem of
        ASTProgram (Program decls) -> do
          length decls `shouldBe` 2
          case decls of
            (ExtDeclUnparsed _ : ExtFunction _ : _) -> do
              recordEntry
                MatrixEntry
                  { meSuite = "AST (semantic)",
                    meName = "struct + main (pattern)",
                    meInput = inp,
                    meExpected = "length decls == 2; ExtDeclUnparsed : ExtFunction",
                    meActual = show sem,
                    meStatus = Pass,
                    meNote = "case/pattern"
                  }
            _ -> expectationFailure "expected struct as ExtDeclUnparsed + main"
        _ -> expectationFailure "expected ASTProgram"

    it "нормализует if/else: ветка else в Maybe, а не AstCompound" $ do
      let inp = "int main() { if (a) b = 1; else b = 2; return 0; }\n"
      sem <- parseSemanticAst inp
      let expected =
            ASTProgram
              ( Program
                  [ ExtFunction
                      ( FunctionDef
                          "main"
                          [SpecType TyInt]
                          []
                          ( SCompound
                              [ SIf
                                  (Sem.EVar "a")
                                  (SExpr (Just (Sem.EAssign AAssign (Sem.EVar "b") (Sem.ELitInt 1))))
                                  (Just (SExpr (Just (Sem.EAssign AAssign (Sem.EVar "b") (Sem.ELitInt 2)))))
                              , SReturn (Just (Sem.ELitInt 0))
                              ]
                          )
                      )
                  ]
              )
      shouldBeRecorded "AST (semantic)" "if/else нормализация" inp expected sem

    it "разбирает локальную декларацию int x;" $ do
      let inp = "int x;"
      decl <- parseLocalDecl inp
      let expected = SDecl (Decl [SpecType TyInt] [Sem.Declarator "x" [] Nothing])
      shouldBeRecorded "AST (semantic)" "локальный int x;" inp expected decl

    it "разбирает C51 data unsigned char dvar на уровне файла" $ do
      let inp = "data unsigned char dvar;\nvoid main(void) { return; }\n"
      sem <- parseSemanticAst inp
      case sem of
        ASTProgram (Program decls) -> do
          let ok =
                any
                  ( \d -> case d of
                      ExtDecl (Decl [SpecC51Memory MemData, SpecType TyUnsigned, SpecType TyChar] [Sem.Declarator "dvar" [] Nothing]) -> True
                      _ -> False
                  )
                  decls
          ok `shouldBe` True
          recordEntry
            MatrixEntry
              { meSuite = "AST (semantic)",
                meName = "C51 data dvar (pattern)",
                meInput = inp,
                meExpected = "any ExtDecl MemData dvar",
                meActual = show sem,
                meStatus = Pass,
                meNote = "any/shouldBe True"
              }
        _ -> expectationFailure "expected ASTProgram"
