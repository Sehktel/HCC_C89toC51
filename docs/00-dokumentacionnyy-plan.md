# План документации HCC C89→C51

> Статус: **review** (версия 0.2, 2026-06-03)  
> Принцип: документация **многофайловая**, перекрёстно связанная, с обязательными схемами на каждом уровне абстракции.

---

## 1. Назначение и область

**HCC C89toC51** — экспериментальный компилятор подмножества C89 с целевой ориентацией на toolchain C51 (8051). Система включает:

- **конвейер преобразования** (10 стадий, каждая — отдельный модуль с контрактом входа/выхода);
- **систему тестирования** (модульные suite, golden-фикстуры `tests/src_c/`, матрица прогона, HTML-отчёт, manifest);
- **инфраструктуру оркестрации** (BPMN/Camunda — целевая, не runtime Haskell).

### Граница текущей итерации документации

**Закрываем описание конвейера до стадии AST включительно** (стадии 1–4):

Preprocessor → Lexer → Parser → **AST**

Стадии 5–10 (IR-лестница, TD, Peephole, Codegen) — каркас в коде; в docs только контракт-заглушка и ссылка на [`11-konveer-kompilyacii.md`](11-konveer-kompilyacii.md) § «За горизонтом AST».

**Система тестирования** — раздел `testing/` + `infra/04-logirovanie.md` (фаза 1b).

---

## 2. Соответствие ГОСТ ЕСПД (адаптированное)

| Код | Вид документа | Файл | Приоритет | Статус итерации |
|-----|---------------|------|-----------|-----------------|
| — | Оглавление | [`README.md`](README.md) | P0 | draft |
| — | План | [`00-dokumentacionnyy-plan.md`](00-dokumentacionnyy-plan.md) | P0 | review |
| ТЗ | Техническое задание | [`01-tehnicheskoe-zadanie.md`](01-tehnicheskoe-zadanie.md) | P1 | stub |
| ПЗ | Пояснительная записка | [`02-poyasnitelnaya-zapiska.md`](02-poyasnitelnaya-zapiska.md) | P1 | stub |
| ОП | Архитектура | [`10-obshchaya-arhitektura.md`](10-obshchaya-arhitektura.md) | P0 | **draft** |
| ОП | Конвейер | [`11-konveer-kompilyacii.md`](11-konveer-kompilyacii.md) | P0 | **draft (фронтенд)** |
| ОП | Стадии 1–4 | [`stages/01..04`](stages/) | P0 | **draft** |
| ОП | Стадии 5–10 | [`stages/05..10`](stages/) | P2 | stub |
| ПМИ | Испытания | [`testing/`](testing/) | P0 | **draft** |
| — | Логирование | [`infra/04-logirovanie.md`](infra/04-logirovanie.md) | P0 | draft |
| РП | Среда, CI | [`infra/`](infra/) | P1 | stub |

### Формат и литеры

| Решение | Значение |
|---------|----------|
| Рабочий формат | **Markdown в репозитории** — единственный источник истины |
| Титульные листы, docx/PDF | **Отложены.** Сначала содержание, потом конвертеры |
| Литеры документов (ЕСПД) | **Назначим позже** при стабилизации комплекта |
| Нумерация рисунков | **По разделу** (`Рис. 11-1`, `Рис. S-02-1`) |

---

## 3. Дерево документов

*(без изменений структуры каталогов — см. версия 0.1)*

Полное дерево: [`README.md`](README.md).

---

## 4. Принятые архитектурные решения (§9 закрыт)

| # | Вопрос | Решение |
|---|--------|---------|
| 1 | Формат | md в repo |
| 2 | PDF/docx/титулы | отложены |
| 3 | Нумерация рисунков | по разделу |
| 4 | Codegen | **отдельная стадия 10** |
| 5 | `test-ir` vs `test-high-ir` | **раздельно**; в glossary — «legacy IR»; слияние запланировано |
| 6 | Порядок написания | **сначала конвейер, потом тесты** |
| 7 | Граница итерации | **до AST включительно** |

---

## 5. Фазы написания (актуализировано)

### Фаза 0 — Каркас ✅

- [x] План документации
- [x] `docs/README.md`, заглушки, glossary, diagram-inventory
- [x] Решения §4

### Фаза 1a — Конвейер до AST ✅

1. [x] [`11-konveer-kompilyacii.md`](11-konveer-kompilyacii.md)
2. [x] [`stages/01..04`](stages/)
3. [x] [`10-obshchaya-arhitektura.md`](10-obshchaya-arhitektura.md) — draft (A-1…A-11)

### Фаза 1b — Система тестирования (текущая) ✅

1. [x] [`testing/00-obzor`](testing/00-obzor-sistemy-testirovaniya.md)
2. [x] [`testing/01-struktura-testov`](testing/01-struktura-testov.md)
3. [x] [`testing/02-manifest-i-matrica`](testing/02-manifest-i-matrica.md)
4. [x] [`testing/03-fixtures-src-c`](testing/03-fixtures-src-c.md)
5. [x] [`testing/04-etalony-golden`](testing/04-etalony-golden.md)
6. [x] [`testing/05-pmi`](testing/05-pmi-programma-metodika-ispytaniy.md)
7. [x] [`testing/06-sistema-sbora-i-podstanovok`](testing/06-sistema-sbora-i-podstanovok.md)
8. [x] [`infra/04-logirovanie`](infra/04-logirovanie.md)

**Критерий:** по docs понятно, какой suite проверяет какую стадию, как устроены golden, сбор matrix и logger.

**Итог итерации P0:** [`00-itog-iteracii-dokumentacii.md`](00-itog-iteracii-dokumentacii.md) — checkpoint для возврата.

### Фаза 2 — Формализация (P1)

ТЗ, ПЗ, полная архитектура, infra.

### Фаза 3 — IR…Codegen (P2)

`stages/05..10`, BPMN.

### Фаза 4 — Сопровождение

Листы изменений; литеры ЕСПД; конвертеры md→docx/PDF.

---

## 6. Правила оформления

1. Один вопрос — один файл.
2. Схема перед текстом для потоков и структур.
3. Mermaid в `.md`; BPMN в `bpmn/*.bpmn`.
4. Черновики `ai/` не входят в официальный комплект.
5. Язык: русский; идентификаторы — как в коде.

---

## 10. История изменений

| Версия | Дата | Изменение |
|--------|------|-----------|
| 0.1 | 2026-06-03 | Первоначальный план |
| 0.2 | 2026-06-03 | Решения §4; граница AST; фазы 1a/1b |
| 0.3 | 2026-06-03 | Фаза 1b: testing/00..05 |
| 0.4 | 2026-06-03 | testing/06 (сбор/подстановки), infra/04 (logger) |
| 0.5 | 2026-06-03 | 10-obshchaya-arhitektura (схемы A-1…A-11) |
| 0.6 | 2026-06-03 | Итог итерации: [`00-itog-iteracii-dokumentacii.md`](00-itog-iteracii-dokumentacii.md) |
