# Синтаксическое vs семантическое дерево (лекционная схема)

Материал для курса по компиляторам на примере **HCC_C89toC51**  
(`Parser.Ast` / `Expr` — синтаксис, модуль `AST` — семантика).

---

## Рис. 1. Общий конвейер компиляции

```mermaid
flowchart TB
  subgraph source["Исходник C89"]
    SRC["файл .c / .h"]
  end

  subgraph front["Фронтенд (анализ)"]
    PP["Препроцессор"]
    LEX["Лексер → Token"]
    PAR["Парсер → Parser.Ast, Expr"]
    SEM["fromParserAst → AST"]
    OPT["Оптимизации на AST<br/>const prop, range check, simplify"]
  end

  subgraph mid["Средний уровень"]
    HIR["buildHighIR → HighIR"]
    MIR["MediumIR"]
    LIR["LowIR"]
  end

  subgraph back["Бэкенд"]
    CG["Генерация кода C51 / asm"]
  end

  SRC --> PP --> LEX --> PAR
  PAR -->|"синтаксис: форма по грамматике"| SEM
  SEM -->|"семантика: типы, scope, смысл"| OPT
  OPT --> HIR --> MIR --> LIR --> CG

  style PAR fill:#e8f4fc,stroke:#1565c0
  style SEM fill:#fff3e0,stroke:#e65100
  style OPT fill:#fff3e0,stroke:#e65100
```

**Легенда:** голубой блок — ответ на вопрос *«как написано?»*; оранжевый — *«что это значит и можно ли оптимизировать?»*

---

## Рис. 2. Два дерева: один исходник — два представления

```mermaid
flowchart LR
  subgraph Q["Вопрос"]
    Q1["Как это<br/>написано?"]
    Q2["Что это<br/>означает?"]
  end

  subgraph SYN["Синтаксическое дерево"]
    direction TB
    S1["Parser.Ast / Expr"]
    S2["Структура по грамматике C"]
    S3["Декларация = список Token"]
    S4["Имя = String"]
    S5["Близко к тексту исходника"]
    S1 --> S2 --> S3 --> S4 --> S5
  end

  subgraph SEM["Семантическое дерево"]
    direction TB
    M1["AST (модуль AST.hs)"]
    M2["Сущности языка + типы"]
    M3["Decl { name, type, storage }"]
    M4["Ссылка на Symbol в scope"]
    M5["Готово для анализа и opt"]
    M1 --> M2 --> M3 --> M4 --> M5
  end

  Q1 --> SYN
  Q2 --> SEM

  PAR2["Парсер"] --> SYN
  SYN -->|"fromParserAst<br/>разбор деклараций, типы, scope"| SEM

  style SYN fill:#e3f2fd,stroke:#1976d2
  style SEM fill:#ffe0b2,stroke:#ef6c00
```

---

## Рис. 3. Пример: одна строка исходника

Исходник:

```c
unsigned char x = 255;
```

```mermaid
flowchart TB
  subgraph code["Исходный текст"]
    T["unsigned char x = 255 ;"]
  end

  subgraph syn_tree["Синтаксическое дерево (упрощённо)"]
    direction TB
    AD["AstDeclaration"]
    TOK["[ TokenKwUnsigned, TokenKwChar,<br/>TokenIdent x, TokenEq,<br/>TokenInt 255, TokenSemi ]"]
    EL["ExprAssign … ExprLitInt 255"]
    AD --> TOK
    AD -.-> EL
  end

  subgraph sem_tree["Семантическое дерево (целевой вид)"]
    direction TB
    D["Decl"]
    NM["name: x"]
    TY["type: unsigned char"]
    ST["storage: auto"]
    INIT["init: Const 255<br/>⚠ range check: 255 ∈ [0,255] ✓"]
    D --> NM
    D --> TY
    D --> ST
    D --> INIT
  end

  T --> LEX2["Lexer"] --> PAR3["Parser"] --> syn_tree
  syn_tree --> FA["fromParserAst +<br/>семантический анализ"] --> sem_tree
  sem_tree --> OP["const prop / fold / warnings"]

  style syn_tree fill:#e8eaf6
  style sem_tree fill:#fff8e1
```

**Для лекции:** на синтаксическом уровне мы видим *последовательность токенов*; на семантическом — *тип, переменную и проверяемое значение*.

---

## Рис. 4. Что где делать (чтобы не путать слои)

```mermaid
flowchart TB
  subgraph syn_ok["Уместно на Parser.Ast"]
    A1["Восстановить структуру операторов"]
    A2["Сообщить синтаксическую ошибку"]
    A3["Сохранить форму for / switch / ?: "]
  end

  subgraph sem_ok["Уместно на AST"]
    B1["Таблица символов, typedef, enum"]
    B2["Проверка типов C89"]
    B3["Распространение констант"]
    B4["Проверка диапазонов / переполнений"]
    B5["Упрощение if / dead pure code"]
    B6["Desugaring перед IR"]
  end

  subgraph ir_ok["Уместно на HighIR и ниже"]
    C1["Временные переменные, basic blocks"]
    C2["Выбор инструкций под 8051"]
    C3["Распределение регистров / памяти"]
  end

  PAR4["Parser.Ast"] --> syn_ok
  syn_ok --> AST2["AST"]
  AST2 --> sem_ok
  sem_ok --> HIR2["HighIR …"]
  HIR2 --> ir_ok
```

---

## Рис. 5. Слои данных (стек представлений)

```mermaid
block-beta
  columns 1
  block:layer5:1
    columns 1
    src["Исходник C89"]
  end
  block:layer4:1
    columns 1
    tok["[Token] — линейная лента"]
  end
  block:layer3:1
    columns 1
    parse["Parser.Expr / Parser.Ast — ДЕРЕВО СИНТАКСИСА"]
  end
  block:layer2:1
    columns 1
    ast["AST — ДЕРЕВО СЕМАНТИКИ (+ оптимизации)"]
  end
  block:layer1:1
    columns 1
    ir["HighIR → MediumIR → LowIR — IR"]
  end
  block:layer0:1
    columns 1
    out["Код C51 / ассемблер"]
  end

  layer5 --> layer4 --> layer3 --> layer2 --> layer1 --> layer0

  style layer3 fill:#bbdefb
  style layer2 fill:#ffcc80
```

---

## Краткая шпаргалка (один слайд)

| | **Синтаксис** (`Parser`) | **Семантика** (`AST`) |
|---|--------------------------|------------------------|
| **Вопрос** | Как записано? | Что означает? |
| **Строится** | Сразу после парсера | После `fromParserAst` + анализ |
| **Декларация** | `[Token]` | `Decl` + `Type` |
| **Идентификатор** | `String` | `Symbol` в scope |
| **Ошибки** | «Не ожидали `;`» | «Тип не согласован», «255 не влезает» |
| **Оптимизации** | Нет | const prop, range, simplify |
| **Дальше** | → `AST` | → `HighIR` |

---

## Экспорт в слайды

- **Mermaid Live Editor:** https://mermaid.live — вставить блок ` ```mermaid ` из этого файла.
- **VS Code / Cursor:** предпросмотр Markdown с поддержкой Mermaid.
- **Reveal.js / Marp:** подключить `mermaid` plugin для лекций из этого `.md`.

Файл в репозитории: `docs/lecture-syntax-vs-semantic-ast.md`
