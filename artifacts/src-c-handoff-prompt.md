# Промпт для продолжения ручных эталонов tests/src_c

Скопируй целиком в следующий чат с ИИ.

---

## Контекст проекта

Репозиторий: **HCC_C89toC51** — компилятор C89→C51 на Haskell.

Задача: **ручные эталонные файлы** для фикстур `tests/src_c/**/*.c`.

**Смысл тестов:** эталон — независимая спецификация. Если эталон = вывод hcc/lexer/parser, то «баг компилятора == баг теста» — тесты бессмысленны.

## СТРОГИЙ запрет на генераторы

**ЗАПРЕЩЕНО** (любой способ получить эталон из кода проекта):

- Запуск **hcc** / exe компилятора «сохранить `.pp`/`.l`/`.p`/`.ir`»
- **`GenSrcCGoldens`** и любые скрипты «dump goldens from pipeline»
- **`cabal repl` / `runghc` / `ghci -e`** с `preprocess`, `lexerPure`, `parseTokensPure`, `show` → файл
- Временные `.hs`/`.py`/one-liner «прогнать Lexer/Parser и записать результат»
- «Проверить эталон генератором и принять вывод как эталон»
- Автоматическая **трансформация** `.pp`→`.l`→`.p` (regex, шаблоны, codegen) без ручного разбора по стадиям

**РАЗРЕШЕНО:**

- Писать эталоны **руками**, читая `Lexer.hs`, `Parser.hs`, `Preprocessor.hs` и **образцы** соседних golden-файлов
- **`c_adv/` workflow:** один раз вручную — `tests/src_c/c_adv/_prefix/common-prefix.{pp,l}`; на каждый `.c` — тело в `<relDir>/<stem>.body.*`; **склейка prefix+body в редакторе** → полные `<stem>.{pp,l,p}` рядом с `.c` (без PS1)
- Запуск **тестов** (`cabal test test-preprocessor`, …) **после** написания — чтобы увидеть расхождение; падение теста **не** повод перезаписать эталон выводом раннера

**Если сомневаешься — не генерируй. Пиши вручную.**

## Правила (обязательно)

1. **Эталоны пишем руками** по C89 / Keil / `.lst`; спецификация — `Lexer.hs`, `Parser.hs`, `Preprocessor.hs`; **не** вывод hcc и не dump lexer/parser.
2. См. блок **«СТРОГИЙ запрет на генераторы»** выше — без исключений.
3. На каждый `.c` — до **5 файлов** с тем же stem:
   - `.pp` — текст **после** препроцессора (комментарии убраны, `#define`/`#include`/`#ifdef` развёрнуты)
   - `.l` — токены **post-PP** текста (`show [Token…]`, одна строка)
   - `.p` / `.ast` — AST **post-PP** (`show AstProgram …`, формат как в `tests/src_c/200_c51/*.p`)
   - `.ir` — пока `[IrUnknown]`, кроме тривиального `main(){ return N; }` → `[IrFunction "main", IrReturnConst N]`
4. **`<reg51.h>` / `"reg2051.h"`:** в `.pp` — **полный inline** заголовка из репозитория (`tests/src_c/c_adv/_headers/reg2051.h`), не сокращённая выдержка.
5. **Раннеры сегодня:** Lex/Parse читают **сырой** `.c`; эталоны `.l`/`.p` — **post-PP**. Красные тесты на `#define`/`#include` — **ожидаемо** до правки раннеров.

## Прогресс

Трекер: **`artifacts/src-c-manual-goldens-todo.md`**

| Каталог | готово | всего | примечание |
|---------|--------|-------|------------|
| `c_base/` | **38** | 38 | ⚠ `test_25_singleton_guard.c` отложен |
| `c_adv/` | **6×.pp+.ir+.l** | 6 | ⏸ `.p`/`.ast` — отложено, разобрать вручную |
| `keil/` | 0 | 10 | можно опираться на `Listings/*.lst` |
| **Итого** | **44** частично | 54 | см. todo |

### c_base — осталось

- ⚠ **`test_25_singleton_guard.c`** — `#error` при двойном `#include`; эталоны не заданы
- **`test_all_constructs.c`** — ✓ все эталоны (ручные)

### c_adv (6) — ⏸ отложено

`main_test.c`, `test_bit_operations.c`, `test_interrupt_setup.c`, `test_memory_types.c`, `test_port_operations.c`, `test_timer_operations.c`  
Зависимости: `_headers/common.h`, `_headers/reg2051.h`.

**Статус:** `.pp`/`.l`/`.ir` есть; `.p`/`.ast` — **нет**. Дописать **вручную** по [`GOLDENS.md`](../tests/src_c/c_adv/GOLDENS.md).

### keil (10)

Workflow: [`tests/src_c/keil/README.md`](../tests/src_c/keil/README.md) — **эталоны в дереве `tests/src_c/keil/`** (не в `artifacts/`).

| relDir | prefix | исходник |
|--------|--------|----------|
| `test1` | none | `test1/test1.c` ✓ эталоны |
| `test2` | reg2051 | `test2/test2.c` ✓ эталоны |
| `0_blink_0` | reg2051 | `blink.c` |
| … | см. `tests/src_c/keil/golden-manifest.json` | |

## Инфраструктура

- `tests/SrcCFixtures.hs`, `Preprocessor_test.hs`, `IR_test.hs`, `IrGolden.hs`
- `artifacts/src-c-fixture-think-about.md` — PP→Lex→Parse, открытые вопросы
- `tests/src_c/c_adv/GOLDENS.md` — эталоны в дереве c_adv/, без PS1
- `tests/src_c/keil/README.md` — эталоны в дереве keil/, без PS1

## Образцы

`c_base/test_01_var_decl.*`, `200_c51/test_205_c51_sbit_xor.*`, `c_base/test_18_switch.*`, `c_base/test_07_include.*`

## Workflow

1. Читать `.c` + `.h`
2. Ручной post-PP → `.pp`
3. Ручные токены → `.l`
4. Ручной AST → `.p` / `.ast`
5. `.ir` по правилу
6. Обновить `artifacts/src-c-manual-goldens-todo.md`
7. Не коммитить без запроса

**`c_adv/`:** общий post-PP префикс — `tests/src_c/c_adv/_prefix/common-prefix.{pp,l}`; тело — `<relDir>/<stem>.body.*`; полные эталоны — рядом с `.c`. См. `GOLDENS.md`.

## Следующий шаг

1. **`keil/`** (10×5) — приоритет
2. **`c_adv/`** — ⏸ отложено; `.p`/`.ast` дописать **вручную** (prefix + body → склейка в редакторе)
3. (Опц.) `test_25` + правка раннеров Lex/Parse

`just audit-src-c`
