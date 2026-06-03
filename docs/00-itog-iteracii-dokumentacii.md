# Итог итерации документации HCC C89→C51

> **Checkpoint** · 2026-06-03 · вернуться к этому файлу при продолжении работ  
> План: [`00-dokumentacionnyy-plan.md`](00-dokumentacionnyy-plan.md) · Оглавление: [`README.md`](README.md)

---

## 1. Статус одной строкой

**Итерация P0 (фазы 0, 1a, 1b) — закрыта.**  
Описаны: общая архитектура, конвейер до AST, система тестирования, логирование.  
Статус документов: **`draft`** (не `stable` — нужна рецензия автора).

---

## 2. Принятые решения (зафиксированы)

| # | Решение |
|---|---------|
| 1 | Источник истины — **Markdown в repo** |
| 2 | PDF / docx / титульные листы — **отложены** |
| 3 | Codegen — **отдельная стадия 10** |
| 4 | `test-ir` и `test-high-ir` — **раздельно**, слияние позже |
| 5 | Порядок написания: конвейер → тесты |
| 6 | **Граница итерации:** стадии 1–4 (PP → Lex → Parse → AST) |
| 7 | Литеры ЕСПД — **назначим позже** |
| 8 | Нумерация рисунков — **по разделу** (P-*, A-*, T-*, S-*, L-*) |

---

## 3. Что сделано (файлы)

### 3.1. Управление документацией

| Файл | Содержание |
|------|------------|
| [`00-dokumentacionnyy-plan.md`](00-dokumentacionnyy-plan.md) | план, фазы, решения (v0.5) |
| [`README.md`](README.md) | оглавление, быстрый вход, статусы |
| [`appendix/glossary.md`](appendix/glossary.md) | термины |
| [`appendix/diagram-inventory.md`](appendix/diagram-inventory.md) | реестр схем |
| **этот файл** | итог для возврата |

### 3.2. Архитектура и конвейер (фаза 1a)

| Файл | Схемы | Статус |
|------|-------|--------|
| [`10-obshchaya-arhitektura.md`](10-obshchaya-arhitektura.md) | A-1 … A-11 | draft |
| [`11-konveer-kompilyacii.md`](11-konveer-kompilyacii.md) | P-1, P-2, P-4, P-6, ошибки | draft |
| [`stages/01-preprocessor.md`](stages/01-preprocessor.md) | S-01-* | draft |
| [`stages/02-lexer.md`](stages/02-lexer.md) | S-02-* | draft |
| [`stages/03-parser.md`](stages/03-parser.md) | S-03-* | draft |
| [`stages/04-ast.md`](stages/04-ast.md) | S-04-* | draft |
| [`stages/05..10`](stages/README.md) | — | **stub** (каркас) |

### 3.3. Тестирование и инфраструктура (фаза 1b)

| Файл | Статус |
|------|--------|
| [`testing/00-obzor-sistemy-testirovaniya.md`](testing/00-obzor-sistemy-testirovaniya.md) | draft |
| [`testing/01-struktura-testov.md`](testing/01-struktura-testov.md) | draft |
| [`testing/02-manifest-i-matrica.md`](testing/02-manifest-i-matrica.md) | draft |
| [`testing/03-fixtures-src-c.md`](testing/03-fixtures-src-c.md) | draft |
| [`testing/04-etalony-golden.md`](testing/04-etalony-golden.md) | draft |
| [`testing/05-pmi-programma-metodika-ispytaniy.md`](testing/05-pmi-programma-metodika-ispytaniy.md) | draft |
| [`testing/06-sistema-sbora-i-podstanovok.md`](testing/06-sistema-sbora-i-podstanovok.md) | draft |
| [`infra/04-logirovanie.md`](infra/04-logirovanie.md) | draft |

### 3.4. Корневой README

[`../README.md`](../README.md) — краткий вход, ссылки на `docs/`.

---

## 4. Ключевые архитектурные тезисы (не забыть)

### Конвейер

```
.c → Preprocessor → Lexer → Parser → AST → [HighIR … Codegen]
         String      [Token]  Parser.Ast   AST
```

- **Два дерева:** `Parser.Ast` (синтаксис) ≠ `AST` (семантика); мост — `fromParserAst`.
- **За горизонтом AST:** HIR → MIR → LIR → TD → Peephole → Codegen — каркас в коде.

### Три поперечные системы

| Система | Модуль | Назначение |
|---------|--------|------------|
| Конвейер | `src/*.hs` | преобразование |
| Логирование | `Logger.hs` | stderr / silent, **не** влияет на golden |
| Сбор тестов | `TestMatrix`, `SrcCFixtures` | JSON matrix, discover, подстановки |

### Тесты: сбор и подстановки

- **Сбор:** `shouldBeRecorded` → `TestMatrix` → `artifacts/test-matrix.json` → HTML / markdown.
- **Discover:** `discover*Fixtures` — пара `.c` + golden ext.
- **Подстановка входа:** Lex/Parser — `.pp` если есть, иначе `preprocess(.c)`; IR — всегда из `.c`.
- **Golden:** ручные эталоны; **запрет** dump lexer/parser в `.l`/`.p`.
- **Pure API для golden:** `lexerPure`, `parseTokensPure`.

### Логирование

- Тесты: `silentLogger`.
- CLI (`app/Main.hs`): `stderrLoggerFor LogInfo`.
- AST: без лога (pure).

---

## 5. Известные пробелы (код + docs)

| # | Пробел |
|---|--------|
| 1 | Нет golden для **семантического AST** (только inline в `AST_test`) |
| 2 | `c_adv/`: `.p`/`.ast` — **0/6** |
| 3 | IR-раннер не читает `.pp` (расхождение с Lex/Parser) |
| 4 | High IR … System pipeline — **pending** в тестах |
| 5 | `artifacts/src-c-golden-workflow.md` — параллельный черновик; канон → `testing/04` |

---

## 6. Не сделано (следующие фазы)

### Фаза 2 (P1)

- [ ] [`01-tehnicheskoe-zadanie.md`](01-tehnicheskoe-zadanie.md) — подмножество C89, критерии приёмки
- [ ] [`02-poyasnitelnaya-zapiska.md`](02-poyasnitelnaya-zapiska.md) — обоснование двух AST, IR-лестницы
- [ ] [`infra/01-sreda-razrabotki.md`](infra/01-sreda-razrabotki.md)
- [ ] [`infra/02-sborka-i-ci.md`](infra/02-sborka-i-ci.md)

### Фаза 3 (P2)

- [ ] [`stages/05..10`](stages/) — HIR … Codegen
- [ ] [`infra/03-orkestraciya-bpmn.md`](infra/03-orkestraciya-bpmn.md) — консолидация из `bpmn-hcc-compilation-pipeline.md`

### Фаза 4

- [ ] Литеры документов (ЕСПД)
- [ ] Конвертеры md → docx/PDF
- [ ] Перевод P0-документов `draft` → `stable` после рецензии
- [ ] Влить `lecture-syntax-vs-semantic-ast.md` в `stages/04` как приложение

---

## 7. Карта «куда идти дальше»

```mermaid
flowchart LR
  NOW["Сейчас:<br/>P0 закрыт"]
  REV["Рецензия draft"]
  P1["Фаза 2: ТЗ, ПЗ, infra"]
  P2["Фаза 3: IR…Codegen"]
  P4["Литеры, PDF"]

  NOW --> REV
  REV --> P1
  P1 --> P2
  P2 --> P4
```

**Рекомендуемый следующий шаг:** рецензия P0 → при необходимости правки → **ТЗ** (`01-tehnicheskoe-zadanie`) или **stages/05** когда начнётся реализация High IR.

---

## 8. Быстрые команды (напоминание)

```powershell
just build
just test-toolchain      # PP, Lex, Parse, AST, IR…
just test-web-report     # HTML + matrix
just audit-src-c         # матрица src_c без Haskell
just open-report
```

---

## 9. Связанные материалы вне `docs/`

| Путь | Роль |
|------|------|
| `artifacts/src-c-matrix.md` | авто-матрица 79 `.c` |
| `artifacts/src-c-golden-workflow.md` | рабочий черновик golden (→ перенос в testing/04) |
| `ai/cursor_*.md` | **не** официальная документация |
| `bpmn/*.bpmn` | оркестрация (XML) |
| `docs/lecture-syntax-vs-semantic-ast.md` | учебный материал |

---

## 10. История checkpoint

| Дата | Событие |
|------|---------|
| 2026-06-03 | Старт: план, каркас docs/ |
| 2026-06-03 | Фаза 1a: конвейер до AST |
| 2026-06-03 | Фаза 1b: testing/00–06, infra/04 |
| 2026-06-03 | 10-obshchaya-arhitektura (A-1…A-11) |
| 2026-06-03 | **Этот итог** — итерация P0 закрыта |

---

*При возобновлении: открыть этот файл → §6 «Не сделано» → §7 «Куда идти дальше».*
