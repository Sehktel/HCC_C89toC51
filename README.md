# HCC C89 to C51

Minimal experimental compiler pipeline for translating a C89-like subset toward C51-oriented tooling.

## Project Structure

- `src/Lexer.hs` - tokenization for keywords, operators, literals, and integer suffixes.
- `src/Preprocessor.hs` - basic source normalization stage.
- `src/Parser.hs` - simplified AST construction for the current supported pattern.
- `app/Main.hs` - demo pipeline entrypoint (`preprocess -> lexer -> parseTokens`).
- `tests/` - component and pipeline test suites.

## Build

```powershell
cabal build all
```

## Run Demo Executable

```powershell
cabal run exe:hcc-c89toc51
```

## Test Strategy

The repository contains both aggregate and focused test suites:

- `hcc-c89toc51-test` - aggregate test suite.
- `test-lexer` - lexer-focused checks.
- `test-parser` - parser-focused checks.
- `test-preprocessor` - preprocessor-focused checks.
- `test-ast` - intermediate AST pipeline checks.
- `test-ir` - intermediate IR pipeline checks.
- `test-pipeline` - end-to-end staged pipeline checks.

Run all suites:

```powershell
cabal test all
```

Run one suite:

```powershell
cabal test test-lexer
```
