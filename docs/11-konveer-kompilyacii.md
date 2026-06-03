# Конвейер компиляции

> Статус: **draft** (фронтенд, стадии 1–4) · Приоритет: P0  
> Схемы: P-1, P-2, P-4, P-6

---

## 1. Назначение

Документ описывает сквозное преобразование исходного C89/C51-текста через **фронтенд компилятора** — до семантического AST включительно. Это **закрытый контур** текущей итерации проекта и документации.

Стадии после AST (High IR … Codegen) перечислены для контекста; детали — в [`stages/README.md`](stages/README.md) (каркас).

---

## 2. Полный конвейер (Рис. P-1)

```mermaid
flowchart TB
  SRC["Исходник .c / .h"]

  subgraph FE["Фронтенд — закрытый контур итерации"]
    PP["1. Preprocessor"]
    LEX["2. Lexer"]
    PAR["3. Parser"]
    AST["4. AST<br/>fromParserAst"]
  end

  subgraph BE["Бэкенд — каркас / planned"]
    HIR["5. High IR"]
    MIR["6. Medium IR"]
    LIR["7. Low IR"]
    TD["8. Tree Destroyer"]
    PH["9. Peephole"]
    CG["10. Codegen"]
  end

  SRC --> PP --> LEX --> PAR --> AST
  AST --> HIR --> MIR --> LIR --> TD --> PH --> CG

  style FE fill:#e8f5e9,stroke:#2e7d32
  style PAR fill:#e8f4fc,stroke:#1565c0
  style AST fill:#fff3e0,stroke:#e65100
  style BE fill:#f5f5f5,stroke:#9e9e9e
```

**Рис. P-1.** Зелёная зона — документирована и реализована в рабочем объёме. Серая — каркас модулей, логика TODO.

---

## 3. Фронтенд: сквозной поток данных (Рис. P-6)

```mermaid
flowchart LR
  C["String<br/>исходник .c"]
  PPout["String<br/>post-PP текст"]
  TOK["[Token]"]
  SYN["Parser.Ast"]
  SEM["AST"]

  C -->|"preprocess"| PPout
  PPout -->|"lexer"| TOK
  TOK -->|"parseTokens"| SYN
  SYN -->|"fromParserAst"| SEM
```

Каждая стрелка — **строгий контракт**: выход стадии N является единственным допустимым входом стадии N+1. Пропуск стадий не предусмотрен.

### Типовой вызов (как в `app/Main.hs` и тестах)

```haskell
preprocessed <- preprocess cfg mbSourcePath sourceCode
tokens       <- lexer pipelineLog preprocessed   -- Logger: сводка + TokenLexError
synAst       <- parseTokens pipelineLog tokens   -- Logger: AstUnknown
semAst       =  fromParserAst synAst             -- pure, без лога
```

`Logger` — см. [infra/04-logirovanie.md](infra/04-logirovanie.md). В тестах обычно `silentLogger`; golden используют `*Pure` без лога.

---

## 4. Два представления дерева (Рис. P-2)

```mermaid
flowchart LR
  subgraph Q["Вопрос"]
    Q1["Как написано<br/>по грамматике?"]
    Q2["Какие сущности<br/>программы?"]
  end

  SYN["Parser.Ast / Expr"]
  SEM["AST / Stmt / Decl"]

  Q1 --> SYN
  Q2 --> SEM
  SYN -->|"fromParserAst"| SEM
```

| | `Parser.Ast` | `AST` |
|---|--------------|-------|
| Модуль | `Parser.hs` | `AST.hs` |
| Декларации | `AstDeclaration [Token]` — сырой фрагмент | `Decl`, `Declarator`, `DeclSpecifier` |
| Функция | `AstFunctionDef name specToks c51Toks body` | `FunctionDef` с разобранными spec |
| Ошибка | `AstUnknown [Token]` | `ASTUnknown [Token]` |
| Типизация C89 | нет | структурная форма, **без** полной sem-check IR |

Подробнее: [`stages/03-parser.md`](stages/03-parser.md), [`stages/04-ast.md`](stages/04-ast.md), [`lecture-syntax-vs-semantic-ast.md`](lecture-syntax-vs-semantic-ast.md).

---

## 5. Контракты стадий фронтенда (Рис. P-4)

| № | Стадия | Вход | Выход | API | Документ |
|---|--------|------|-------|-----|----------|
| 1 | Preprocessor | `String`, `PreprocessConfig`, `Maybe FilePath` | `IO String` | `preprocess` | [stages/01-preprocessor.md](stages/01-preprocessor.md) |
| 2 | Lexer | `String` | `IO [Token]` | `lexer`, `lexerPure` | [stages/02-lexer.md](stages/02-lexer.md) |
| 3 | Parser | `[Token]` | `IO Parser.Ast` | `parseTokens`, `parseTokensPure` | [stages/03-parser.md](stages/03-parser.md) |
| 4 | AST | `Parser.Ast` | `AST` | `fromParserAst` | [stages/04-ast.md](stages/04-ast.md) |

### Инварианты между стадиями

1. **Preprocessor → Lexer:** директив `#…` в выходе отсутствуют; текст — логические строки C без обработки PP.
2. **Lexer → Parser:** последовательность заканчивается разбором всей translation unit; «хвост» токенов = `AstUnknown`.
3. **Parser → AST:** `fromParserAst` не читает исходный текст и не вызывает лексер; только структурный подъём.

---

## 6. Обработка ошибок на фронтенде

```mermaid
flowchart TD
  PP{"Preprocessor<br/>IO error?"}
  LEX{"TokenLexError<br/>в потоке?"}
  PAR{"parseTranslationUnit<br/>успех?"}
  AST{"fromParserAst<br/>распознал?"}

  PP -->|include не найден| FAIL1["IO Exception"]
  PP -->|ok| LEX
  LEX -->|есть| WARN1["TokenLexError + продолжение"]
  LEX --> PAR
  PAR -->|нет| UNK1["AstUnknown"]
  PAR -->|да| AST
  AST -->|частично| UNK2["ASTUnknown / ExtDeclUnparsed"]
  AST -->|ok| OK["ASTProgram"]
```

| Стадия | Стратегия | Маркер |
|--------|-----------|--------|
| Preprocessor | fail-fast на битый `#include` | `IO Error` |
| Lexer | ошибка как токен | `TokenLexError String` |
| Parser | мягкий fallback | `AstUnknown [Token]` |
| AST | частичный подъём | `ASTUnknown`, `ExtDeclUnparsed`, `SDeclUnparsed` |

Полная типизация и диагностика диапазонов — **не** на AST; задача IR (стадия 5+).

---

## 7. За горизонтом AST (стадии 5–10, каркас)

| № | Стадия | Вход → выход | Зрелость |
|---|--------|--------------|----------|
| 5 | High IR | `AST` → `HighIR` | каркас (`HighIRTodo`) |
| 6 | Medium IR | `HighIR` → `MediumIR` | каркас |
| 7 | Low IR | `MediumIR` → `LowIR` | каркас |
| 8 | Tree Destroyer | `LowIR` → `TDResult` | каркас |
| 9 | Peephole | `TDResult` → `PeepholeResult` | каркас |
| 10 | **Codegen** | `PeepholeResult` → asm/C51 | **planned** (отдельная стадия) |

Legacy-suite `test-ir` и будущий `test-high-ir` **пока раздельны**; слияние запланировано (см. [glossary](appendix/glossary.md)).

---

## 8. Связанные документы

| Документ | Содержание |
|----------|------------|
| [10-obshchaya-arhitektura.md](10-obshchaya-arhitektura.md) | **общая архитектура**, 11 схем |
| [stages/01-preprocessor.md](stages/01-preprocessor.md) | директивы PP, include, макросы |
| [stages/02-lexer.md](stages/02-lexer.md) | токены, C51-ключевые слова |
| [stages/03-parser.md](stages/03-parser.md) | грамматика, приоритеты |
| [stages/04-ast.md](stages/04-ast.md) | семантический подъём |
| [00-dokumentacionnyy-plan.md](00-dokumentacionnyy-plan.md) | план, фазы |
| [testing/](../testing/) | *следующий блок документации* |

---

## 10. История изменений

| Версия | Дата | Изменение |
|--------|------|-----------|
| 0.1 | 2026-06-03 | Каркас P-1, таблица контрактов |
| 0.2 | 2026-06-03 | Фронтенд до AST: P-2, P-6, ошибки, граница итерации |
