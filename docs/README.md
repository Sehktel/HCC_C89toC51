# Документация HCC C89→C51

> Официальная многофайловая документация проекта.  
> План и структура: [`00-dokumentacionnyy-plan.md`](00-dokumentacionnyy-plan.md)

---

## Быстрый вход

| Задача | Документ |
|--------|----------|
| **Общая архитектура (схемы)** | [`10-obshchaya-arhitektura.md`](10-obshchaya-arhitektura.md) |
| **Конвейер до AST** | [`11-konveer-kompilyacii.md`](11-konveer-kompilyacii.md) |
| Стадия: препроцессор | [`stages/01-preprocessor.md`](stages/01-preprocessor.md) |
| Стадия: лексер | [`stages/02-lexer.md`](stages/02-lexer.md) |
| Стадия: парсер | [`stages/03-parser.md`](stages/03-parser.md) |
| Стадия: AST | [`stages/04-ast.md`](stages/04-ast.md) |
| План документации | [`00-dokumentacionnyy-plan.md`](00-dokumentacionnyy-plan.md) |
| **Итог итерации (checkpoint)** | [`00-itog-iteracii-dokumentacii.md`](00-itog-iteracii-dokumentacii.md) |
| Тесты | [`testing/00-obzor-sistemy-testirovaniya.md`](testing/00-obzor-sistemy-testirovaniya.md) |
| Golden / эталоны | [`testing/04-etalony-golden.md`](testing/04-etalony-golden.md) |
| ПМИ | [`testing/05-pmi-programma-metodika-ispytaniy.md`](testing/05-pmi-programma-metodika-ispytaniy.md) |
| Сбор/подстановки тестов | [`testing/06-sistema-sbora-i-podstanovok.md`](testing/06-sistema-sbora-i-podstanovok.md) |
| Логирование | [`infra/04-logirovanie.md`](infra/04-logirovanie.md) |

---

## Статус документов

| Документ | Статус | Приоритет |
|----------|--------|-----------|
| [00-dokumentacionnyy-plan.md](00-dokumentacionnyy-plan.md) | **review** | P0 |
| [11-konveer-kompilyacii.md](11-konveer-kompilyacii.md) | **draft** (фронтенд) | P0 |
| [stages/01-preprocessor.md](stages/01-preprocessor.md) | **draft** | P0 |
| [stages/02-lexer.md](stages/02-lexer.md) | **draft** | P0 |
| [stages/03-parser.md](stages/03-parser.md) | **draft** | P0 |
| [stages/04-ast.md](stages/04-ast.md) | **draft** | P0 |
| [stages/05..10](stages/README.md) | stub (каркас) | P2 |
| [testing/00-obzor-sistemy-testirovaniya.md](testing/00-obzor-sistemy-testirovaniya.md) | **draft** | P0 |
| [testing/01..06](testing/) | **draft** | P0 |
| [infra/04-logirovanie.md](infra/04-logirovanie.md) | **draft** | P0 |
| [01-tehnicheskoe-zadanie.md](01-tehnicheskoe-zadanie.md) | stub | P1 |
| [10-obshchaya-arhitektura.md](10-obshchaya-arhitektura.md) | **draft** | P0 |
| [appendix/glossary.md](appendix/glossary.md) | draft | P0 |
| [appendix/diagram-inventory.md](appendix/diagram-inventory.md) | draft | P0 |

**Текущая итерация:** фазы **1a + 1b** завершены (конвейер до AST + система тестирования).

---

## Разделы

### Общие документы

- [01-tehnicheskoe-zadanie.md](01-tehnicheskoe-zadanie.md) — ТЗ
- [02-poyasnitelnaya-zapiska.md](02-poyasnitelnaya-zapiska.md) — пояснительная записка

### Архитектура

- [10-obshchaya-arhitektura.md](10-obshchaya-arhitektura.md)
- [11-konveer-kompilyacii.md](11-konveer-kompilyacii.md)

### Стадии конвейера

| № | Стадия | Модуль | Документ |
|---|--------|--------|----------|
| 1 | Препроцессор | `Preprocessor.hs` | [stages/01-preprocessor.md](stages/01-preprocessor.md) |
| 2 | Лексер | `Lexer.hs` | [stages/02-lexer.md](stages/02-lexer.md) |
| 3 | Парсер | `Parser.hs` | [stages/03-parser.md](stages/03-parser.md) |
| 4 | Семантическое AST | `AST.hs` | [stages/04-ast.md](stages/04-ast.md) |
| 5 | High IR | `HighIR.hs` | [stages/05-high-ir.md](stages/05-high-ir.md) |
| 6 | Medium IR | `MediumIR.hs` | [stages/06-medium-ir.md](stages/06-medium-ir.md) |
| 7 | Low IR | `LowIR.hs` | [stages/07-low-ir.md](stages/07-low-ir.md) |
| 8 | Tree Destroyer | `TreeDestroyer.hs` | [stages/08-tree-destroyer.md](stages/08-tree-destroyer.md) |
| 9 | Peephole | `Peephole.hs` | [stages/09-peephole.md](stages/09-peephole.md) |
| 10 | Codegen | *(planned)* | [stages/10-codegen.md](stages/10-codegen.md) |

### Система тестирования

- [testing/00-obzor-sistemy-testirovaniya.md](testing/00-obzor-sistemy-testirovaniya.md)
- [testing/01-struktura-testov.md](testing/01-struktura-testov.md)
- [testing/02-manifest-i-matrica.md](testing/02-manifest-i-matrica.md)
- [testing/03-fixtures-src-c.md](testing/03-fixtures-src-c.md)
- [testing/04-etalony-golden.md](testing/04-etalony-golden.md)
- [testing/05-pmi-programma-metodika-ispytaniy.md](testing/05-pmi-programma-metodika-ispytaniy.md)
- [testing/06-sistema-sbora-i-podstanovok.md](testing/06-sistema-sbora-i-podstanovok.md)

### Инфраструктура

- [infra/01-sreda-razrabotki.md](infra/01-sreda-razrabotki.md)
- [infra/02-sborka-i-ci.md](infra/02-sborka-i-ci.md)
- [infra/03-orkestraciya-bpmn.md](infra/03-orkestraciya-bpmn.md)
- [infra/04-logirovanie.md](infra/04-logirovanie.md)

### Приложения и legacy

- [appendix/glossary.md](appendix/glossary.md)
- [appendix/diagram-inventory.md](appendix/diagram-inventory.md)
- [lecture-syntax-vs-semantic-ast.md](lecture-syntax-vs-semantic-ast.md) — учебный материал (→ stages/04)
- [bpmn-hcc-compilation-pipeline.md](bpmn-hcc-compilation-pipeline.md) — черновик BPMN (→ infra/03)

---

## Команды (кратко)

```powershell
just build          # cabal build all
just test           # все test-suite
just test-toolchain # стадии конвейера по отдельности
just test-web-report # HTML-отчёт + матрица
just audit-src-c    # аудит tests/src_c
just ci             # build + test + haddock
```

Полное описание — в [`infra/02-sborka-i-ci.md`](infra/02-sborka-i-ci.md) *(planned)*.
