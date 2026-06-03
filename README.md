# HCC C89 to C51

Экспериментальный компилятор подмножества C89 с ориентацией на toolchain C51 (8051).

**Документация:** [`docs/README.md`](docs/README.md) — оглавление.  
**Архитектура:** [`docs/10-obshchaya-arhitektura.md`](docs/10-obshchaya-arhitektura.md).

## Конвейер (кратко)

Preprocessor → Lexer → Parser → AST → High IR → Medium IR → Low IR → Tree Destroyer → Peephole → Codegen

Схема и контракты стадий: [`docs/11-konveer-kompilyacii.md`](docs/11-konveer-kompilyacii.md).  
Система тестирования: [`docs/testing/00-obzor-sistemy-testirovaniya.md`](docs/testing/00-obzor-sistemy-testirovaniya.md).

## Быстрый старт

```powershell
just build          # cabal build all
just test           # все test-suite
just test-web-report # HTML-отчёт
```

Демо-исполняемый файл:

```powershell
cabal run exe:hcc-c89toc51
```

## Структура репозитория

| Каталог | Назначение |
|---------|------------|
| `src/` | модули конвейера |
| `app/` | точка входа |
| `tests/` | hspec suite + `tests/src_c/` golden |
| `docs/` | официальная документация |
| `artifacts/` | отчёты, матрицы, рабочие черновики |
| `bpmn/` | диаграммы оркестрации |
| `justfile` | команды сборки и тестов |

## Ограничения

- `float`, `double` — синтаксически допустимы, операции не реализованы.