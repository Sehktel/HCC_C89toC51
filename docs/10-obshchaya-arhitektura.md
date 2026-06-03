# Общая архитектура HCC C89→C51

> Статус: **draft** · Приоритет: P0  
> Схемы: A-1 … A-9 (см. [appendix/diagram-inventory.md](appendix/diagram-inventory.md))

---

## 1. Назначение

Единый обзор системы: **границы**, **компоненты**, **зависимости**, **три поперечные подсистемы** (конвейер, тестирование, логирование).

Детали конвейера → [11-konveer-kompilyacii.md](11-konveer-kompilyacii.md).  
Детали тестов → [testing/00-obzor-sistemy-testirovaniya.md](testing/00-obzor-sistemy-testirovaniya.md).  
Логирование → [infra/04-logirovanie.md](infra/04-logirovanie.md).

---

## 2. Контекст системы (Рис. A-1)

```mermaid
flowchart TB
  subgraph external["Внешняя среда"]
    DEV["Разработчик / CI"]
    SRC["Исходники .c / .h"]
    KEIL["Keil uVision / C51 toolchain"]
    CAMUNDA["Camunda 7<br/>(целевая оркестрация)"]
  end

  subgraph hcc["HCC C89toC51"]
    COMP["Компилятор<br/>(Haskell)"]
    TEST["Система тестирования"]
    DOC["docs/"]
  end

  subgraph outputs["Выходы (целевые)"]
    ASM["asm / C51"]
    REPORT["test-report.html<br/>test-matrix.json"]
  end

  DEV --> SRC
  DEV --> COMP
  DEV --> TEST
  SRC --> COMP
  COMP --> ASM
  TEST --> REPORT
  COMP -.->|"эталоны сверяются с"| KEIL
  CAMUNDA -.->|"BPMN workers<br/>(planned)"| COMP
```

**Роль HCC:** транслятор подмножества C89 (+ C51-расширения) с поэтапной верификацией. Runtime production — Haskell + Cabal; Camunda — оркестрация сборок, не ядро компилятора.

---

## 3. Структура репозитория (Рис. A-2)

```mermaid
flowchart TB
  ROOT["HCC_C89toC51/"]

  ROOT --> SRC["src/<br/>библиотека конвейера"]
  ROOT --> APP["app/<br/>exe Main.hs"]
  ROOT --> TESTS["tests/<br/>hspec + src_c corpus"]
  ROOT --> DOCS["docs/<br/>официальная документация"]
  ROOT --> ART["artifacts/<br/>отчёты, матрицы, черновики"]
  ROOT --> SCR["scripts/<br/>Python audit, gen_table"]
  ROOT --> BPMN["bpmn/<br/>диаграммы Camunda"]
  ROOT --> GRAM["grammar/<br/>C89 грамматика (справочник)"]
  ROOT --> JUST["justfile / .cabal"]

  TESTS --> SRCC["tests/src_c/<br/>79× .c + golden"]
  TESTS --> TINF["TestMatrix, TestManifest,<br/>SrcCFixtures, IrGolden"]
```

| Каталог | Назначение | Документ |
|---------|------------|----------|
| `src/` | модули стадий + `Logger` | [stages/](stages/) |
| `app/` | демо CLI (PP→Lex→Parse) | — |
| `tests/` | suite + инфраструктура | [testing/](testing/) |
| `docs/` | ЕСПД-структура | [README.md](README.md) |
| `artifacts/` | генерируемые отчёты | [testing/02-manifest](testing/02-manifest-i-matrica.md) |
| `bpmn/` | оркестрация | [infra/03-orkestraciya-bpmn.md](infra/03-orkestraciya-bpmn.md) |

---

## 4. Три поперечные подсистемы (Рис. A-3)

```mermaid
flowchart TB
  subgraph pipeline["1. Конвейер преобразования"]
    direction LR
    P1["Preprocessor"] --> P2["Lexer"] --> P3["Parser"] --> P4["AST"]
    P4 --> P5["HighIR … Codegen"]
  end

  subgraph logging["2. Логирование"]
    LG["Logger.hs<br/>logMsg / logMsgLazy"]
    LG --> STDERR["stderr / silent"]
  end

  subgraph testing["3. Система тестирования"]
    direction TB
    DISC["discover + manifest"]
    COLL["TestMatrix сбор"]
    GOLD["golden src_c"]
    DISC --> COLL
    GOLD --> DISC
  end

  pipeline --> logging
  pipeline --> testing
  testing --> ART2["artifacts/*.json/html"]
```

| Подсистема | Модули | Не путать с |
|------------|--------|-------------|
| Конвейер | `src/*.hs` | — |
| Логирование | `Logger.hs`, `pcLogger` | TestMatrix |
| Тестирование | `TestMatrix`, `SrcCFixtures`, `*_test.hs` | Logger output |

---

## 5. Слои архитектуры (Рис. A-4)

```mermaid
flowchart TB
  subgraph L0["Слой 0: инфраструктура"]
    LOG["Logger"]
    CFG["PreprocessConfig"]
  end

  subgraph L1["Слой 1: фронтенд (реализован)"]
    PP["Preprocessor"]
    LEX["Lexer"]
    PAR["Parser"]
    AST["AST"]
  end

  subgraph L2["Слой 2: IR-лестница (каркас)"]
    HIR["HighIR"]
    MIR["MediumIR"]
    LIR["LowIR"]
  end

  subgraph L3["Слой 3: бэкенд (каркас)"]
    TD["TreeDestroyer"]
    PH["Peephole"]
    CG["Codegen planned"]
  end

  L0 --> L1
  L1 --> L2 --> L3

  style L1 fill:#e8f5e9,stroke:#2e7d32
  style L2 fill:#fff8e1,stroke:#f9a825
  style L3 fill:#f5f5f5,stroke:#9e9e9e
```

**Правило зависимостей:** слой N импортирует только слои ≤ N (и L0). Обратных ссылок нет.

---

## 6. Граф модулей `src/` (Рис. A-5)

```mermaid
flowchart BT
  LOG["Logger"]

  PP["Preprocessor"] --> LOG
  LEX["Lexer"] --> LOG
  PAR["Parser"] --> LEX
  PAR --> LOG

  AST["AST"] --> PAR
  AST --> LEX

  HIR["HighIR"] --> AST
  MIR["MediumIR"] --> HIR
  LIR["LowIR"] --> MIR
  TD["TreeDestroyer"] --> LIR
  PH["Peephole"] --> TD

  style AST fill:#fff3e0
  style PAR fill:#e8f4fc
  style LOG fill:#fce4ec
```

### Таблица модулей

| Модуль | Слой | Зависит от | Экспортирует |
|--------|------|------------|--------------|
| `Logger` | L0 | base | `Logger`, `logMsg`, … |
| `Preprocessor` | L1 | Logger, IO | `preprocess`, `PreprocessConfig` |
| `Lexer` | L1 | Logger | `Token`, `lexer`, `lexerPure` |
| `Parser` | L1 | Lexer, Logger | `Ast`, `parseTokens`, `parseTokensPure` |
| `AST` | L1 | Parser, Lexer | `AST`, `fromParserAst` |
| `HighIR` … `Peephole` | L2–L3 | цепочка IR | каркас API |

---

## 7. Два дерева и чистые API (Рис. A-6)

```mermaid
flowchart LR
  subgraph syntax["Синтаксис"]
    TOK["[Token]"]
    PA["parseTokens / parseTokensPure"]
    SYN["Parser.Ast"]
    TOK --> PA --> SYN
  end

  subgraph semantic["Семантика"]
    LIFT["fromParserAst<br/>(pure)"]
    SEM["AST"]
    SYN --> LIFT --> SEM
  end

  subgraph pure["Pure API (golden)"]
    LXP["lexerPure"]
    PTP["parseTokensPure"]
  end

  subgraph io["IO API (runtime)"]
    LX["lexer + Logger"]
    PT["parseTokens + Logger"]
    PRE["preprocess"]
  end
```

Golden-тесты и audit используют **Pure/IO-ветки** осознанно: см. [testing/06-sistema-sbora-i-podstanovok.md](testing/06-sistema-sbora-i-podstanovok.md).

---

## 8. Сборка и исполнение (Рис. A-7)

```mermaid
flowchart TB
  subgraph build["Сборка (Cabal)"]
    CAB["hcc-c89toc51.cabal"]
    LIB["library : src/"]
    EXE["executable : app/"]
    TS["15× test-suite"]
    CAB --> LIB
    CAB --> EXE
    CAB --> TS
  end

  subgraph run["Исполнение"]
    JUST["justfile"]
    JUST --> B["just build"]
    JUST --> T["just test"]
    JUST --> TW["just test-web-report"]
    JUST --> CI["just ci"]
  end

  subgraph targets["Цели"]
    B --> DIST["dist-newstyle/"]
    T --> LOGS["*.log"]
    TW --> HTML["artifacts/test-report.html"]
    TW --> MAT["artifacts/test-matrix.json"]
  end
```

| Команда | Артеfact |
|---------|----------|
| `just build` | `lib` + `exe:hcc-c89toc51` |
| `just test` | все suite, exit code |
| `just test-web-report` | HTML + matrix + `all-tests-table.md` |
| `just docs` | Haddock |

---

## 9. Архитектура тестирования (Рис. A-8)

```mermaid
flowchart TB
  subgraph sources["Источники кейсов"]
    INLINE["inline в *_test.hs"]
    DISC["SrcCFixtures.discover*"]
    MAN["TestManifest JSON"]
    SRCC["tests/src_c/**/*.c"]
  end

  subgraph runners["Раннеры"]
    SPEC["*_spec.hs → hspec"]
    WEB["WebReport_spec → tasty+HTML"]
    MR["ManifestRunner_spec"]
  end

  subgraph engine["Движок"]
    SBR["shouldBeRecorded"]
    ME["matchTextExpectation"]
    TM["TestMatrix → JSON"]
  end

  SRCC --> DISC
  INLINE --> SBR
  DISC --> SBR
  MAN --> ME --> SBR
  SBR --> TM

  SPEC --> runners
  WEB --> TM
```

Полное описание: [testing/06-sistema-sbora-i-podstanovok.md](testing/06-sistema-sbora-i-podstanovok.md).

---

## 10. Логирование в архитектуре (Рис. A-9)

```mermaid
flowchart LR
  subgraph contexts["Контексты"]
    CLI["app/Main.hs<br/>stderrLoggerFor LogInfo"]
    TEST["cabal test<br/>silentLogger"]
  end

  subgraph inject["Инъекция"]
    CFG["PreprocessConfig.pcLogger"]
    ARG["lexer lg / parseTokens lg"]
  end

  subgraph stages["Стадии с логом"]
    PP2["Preprocessor ppLog"]
    LX2["Lexer Debug+Warn"]
    PR2["Parser Debug+Warn"]
  end

  CLI --> CFG
  CLI --> ARG
  TEST --> CFG
  TEST --> ARG

  CFG --> PP2
  ARG --> LX2
  ARG --> PR2

  PP2 --> OUT["stderr / nop"]
  LX2 --> OUT
  PR2 --> OUT
```

AST и `fromParserAst` — **без** логирования (pure).

---

## 11. Сквозная схема: один прогон fixture (Рис. A-10)

```mermaid
sequenceDiagram
  participant F as tests/src_c/foo.c
  participant R as Parser_test
  participant PP as Preprocessor
  participant L as Lexer
  participant P as Parser
  participant M as TestMatrix
  participant G as foo.p golden

  R->>F: readFile .c
  R->>G: readFile .p
  alt есть foo.pp
    R->>R: readFile .pp
  else
    R->>PP: preprocess(srcCPreprocessConfig)
    PP-->>R: post-PP text
  end
  R->>L: lexer silentLogger
  L-->>R: [Token]
  R->>P: parseTokens silentLogger
  P-->>R: Parser.Ast
  R->>R: show ast
  R->>M: recordCompare + shouldBe
  M->>M: flushMatrix → JSON
```

---

## 12. Целевая оркестрация (Рис. A-11)

```mermaid
flowchart LR
  subgraph camunda["Camunda 7 (planned)"]
    BP["hcc-compilation-pipeline"]
    BC["hcc-batch-coordinator"]
  end

  subgraph workers["External task workers"]
    WPP["hcc-stage-preprocess"]
    WLX["hcc-stage-lexer"]
    WPR["hcc-stage-parse"]
    WHI["hcc-stage-highir"]
    WCG["hcc-stage-codegen"]
  end

  subgraph haskell["Haskell (этот repo)"]
    STAGES["src/ stages"]
    TEST2["cabal test"]
  end

  BP --> workers
  BC --> BP
  workers -->|"cabal / CLI"| STAGES
  workers --> TEST2
```

Детали: [infra/03-orkestraciya-bpmn.md](infra/03-orkestraciya-bpmn.md), `bpmn/hcc-compilation-pipeline.bpmn`.

---

## 13. Технологический стек

| Компонент | Технология |
|-----------|------------|
| Язык компилятора | Haskell2010, GHC 9.x |
| Сборка | Cabal 3.x, `cabal.project` |
| Автоматизация | `just` (PowerShell) |
| Unit/integration | Hspec 2.x |
| Web-отчёт | Tasty + tasty-hspec + tasty-html |
| Matrix JSON | Aeson 2.x |
| Аудит corpus | Python 3 (`scripts/`) |
| Диаграммы docs | Mermaid в Markdown |
| Оркестрация (цель) | BPMN 2.0 / Camunda 7 |
| Целевая платформа | C51 / 8051 (Keil) |

---

## 14. Границы зрелости (текущая итерация)

```mermaid
pie title Зрелость стадий (документировано + тесты)
  "Фронтенд PP–AST" : 4
  "Legacy IR" : 1
  "HIR…Codegen каркас" : 5
```

| Область | Статус |
|---------|--------|
| Фронтенд 1–4 | реализован, golden, docs draft |
| Legacy IR | минимальный `IrGolden`, golden `.ir` |
| HIR … Peephole | каркас + pending tests |
| Codegen | planned |
| AST golden | нет (inline tests) |
| c_adv `.p` | пробел 0/6 |

---

## 15. Связанные документы

| Тема | Документ |
|------|----------|
| Конвейер | [11-konveer-kompilyacii.md](11-konveer-kompilyacii.md) |
| Стадии 1–4 | [stages/01..04](stages/) |
| Тесты | [testing/00](testing/00-obzor-sistemy-testirovaniya.md) |
| Сбор/подстановки | [testing/06](testing/06-sistema-sbora-i-podstanovok.md) |
| Logger | [infra/04-logirovanie.md](infra/04-logirovanie.md) |
| CI | [infra/02-sborka-i-ci.md](infra/02-sborka-i-ci.md) |
| План docs | [00-dokumentacionnyy-plan.md](00-dokumentacionnyy-plan.md) |

---

## 16. История изменений

| Версия | Дата | Изменение |
|--------|------|-----------|
| 0.1 | 2026-06-03 | Полная архитектура, схемы A-1…A-11 |
