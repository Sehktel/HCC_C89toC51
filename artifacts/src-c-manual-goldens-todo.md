# Ручные эталоны tests/src_c — прогресс

**Правило:** эталоны пишем **руками** (C89 / Keil / `.lst`), **не** из вывода hcc.

Файлы на `.c`: `.pp` · `.l` · `.p` · `.ast` · `.ir`

## c_base/ (38)

| # | `.c` | pp | l | p | ast | ir | ▶ |
|---|------|:-:|:-:|:-:|:-:|:-:|:-:|
| 1 | `test_01_var_decl.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 2 | `test_02_assignment.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 3 | `abc.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 4 | `sample.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 5 | `test_03_arithmetic.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 6 | `test_04_for_loop.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 7 | `test_05_while_loop.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 8 | `test_06_if_statement.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 9 | `if_else_then.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 10 | `for_loop_example.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 11 | `multiple_functions.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 12 | `test_07_include.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 13 | `test_08_multi_include.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 14 | `test_09_define.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 15 | `test_11_ifdef.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 16 | `test_13_macro.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 17 | `test_25_singleton_guard.c` | — | — | — | — | — | ⚠ |
| 18 | `01_basic_led.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 19 | `02_bit_operations.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 20 | `03_timer_basic.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 21 | `04_serial_comm.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 22 | `05_external_interrupt.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 23 | `complex_interrupt.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 24 | `interrupt_handler.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 25 | `test_10_interrupt.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 26 | `test_14_ext_int.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 27 | `test_15_bits.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 28 | `test_16_array.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 29 | `test_17_types.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 30 | `test_18_switch.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 31 | `test_19_regbank.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 32 | `test_20_bitwise.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 33 | `test_21_funcptr.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 34 | `test_22_memory.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 35 | `test_23_array.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 36 | `test_24_csumab.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 37 | `test_26_12345bop.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 38 | `test_all_constructs.c` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## c_adv/ (6) — ⏸ отложено

Workflow: [`tests/src_c/c_adv/GOLDENS.md`](../tests/src_c/c_adv/GOLDENS.md) · манифест: `golden-manifest.json` · префикс: `_prefix/common-prefix.*` · заголовки: `_headers/` · **без glue/PS1**

| # | каталог | prefix | pp | l | p | ast | ir | ▶ |
|---|---------|--------|:-:|:-:|:-:|:-:|:-:|:-:|
| 1 | `main_test/main_test.c` | common-prefix | ✓ | ✓ | | | ✓ | ⏸ |
| 2 | `test_bit_operations/test_bit_operations.c` | common-prefix | ✓ | ✓ | | | ✓ | ⏸ |
| 3 | `test_interrupt_setup/test_interrupt_setup.c` | common-prefix | ✓ | ✓ | | | ✓ | ⏸ |
| 4 | `test_memory_types/test_memory_types.c` | common-prefix | ✓ | ✓ | | | ✓ | ⏸ |
| 5 | `test_port_operations/test_port_operations.c` | common-prefix | ✓ | ✓ | | | ✓ | ⏸ |
| 6 | `test_timer_operations/test_timer_operations.c` | common-prefix | ✓ | ✓ | | | ✓ | ⏸ |

**Вернуться и разобраться вручную:** не хватает `.p`/`.ast`. Префикс: `_prefix/common-prefix.{pp,l}` ✓, `.p` — **нет**. Тела: `<stem>.body.{pp,l}` в каждой папке ✓.

## keil/ (10) — эталоны в `tests/src_c/keil/`

Workflow: [`tests/src_c/keil/README.md`](../tests/src_c/keil/README.md) · манифест: `tests/src_c/keil/golden-manifest.json` · префиксы: `_prefix/` · **без glue/PS1**

| # | каталог | prefix | pp | l | p | ast | ir | ▶ |
|---|---------|--------|:-:|:-:|:-:|:-:|:-:|:-:|
| 1 | `test1/test1.c` | none | ✓ | ✓ | ✓ | ✓ | ✓ | ◐ |
| 2 | `test2/test2.c` | reg2051 | ✓ | ✓ | ✓ | ✓ | ✓ | ◐ |
| 3 | `0_blink_0/blink.c` | reg2051 | | | | | | |
| 4 | `0_blink_0_1/blink.c` | reg2051 | | | | | | |
| 5 | `0_declare_0/declare.c` | reg2051 | | | | | | |
| 6 | `0_int0_0/int0.c` | reg2051 | | | | | | |
| 7 | `0_int_0/0_interrupt_0.c` | reg2051 | | | | | | |
| 8 | `0_int_0_1/0_int_0.c` | reg2051 | | | | | | |
| 9 | `0_int_f_0/int_f.c` | reg2051 | | | | | | |
| 10 | `0_test_0/test.c` | reg51 | | | | | | |

**TODO (keil/):** удалить устаревшие `artifacts/keil-*-canonical-*` (дубликаты; рабочие префиксы — `tests/src_c/keil/_prefix/`).

---

## TODO (глобально, раннеры / pipeline)

**Проверить и обеспечить цепочку стадий:** каждый тест потребляет **выход предыдущей** стадии, эталон рядом с `.c` описывает именно этот выход.

```
.c  ──▶  preprocess  ──▶  .pp
              │
              ▼
           lexer(.pp)  ──▶  .l
              │
              ▼
           parser(.l)  ──▶  .p / .ast     ← AST: отдельная стадия, эталон .p ≡ .ast
              │
              ▼
           IR(.ast)     ──▶  .ir
              │
              ▼
         HighIR …       ──▶  .hir / .mir / .lir
```

**Сейчас расхождение** (см. [`src-c-fixture-think-about.md`](src-c-fixture-think-about.md)):

| Стадия | Эталон | Раннер сегодня |
|--------|--------|----------------|
| PP | `.pp` | `preprocess(.c)` ✓ |
| Lex | `.l` (post-PP) | `lexerPure(.c)` — **сырой** `.c` ✗ |
| Parse | `.p` (post-PP) | `lexer(.c)` → parse ✗ |
| IR | `.ir` | PP→lex→parse→IR (ближе, но lex/parse не через `.pp`-эталон) |

**Задача:** поправить `Lexer_test.hs`, `Parser_test.hs`, `IR_test.hs`: цепочка **PP → Lex → Parse → AST → IR**; Lex читает `.pp`, Parse — токены post-PP, IR — AST (не сырой `.c`). Эталоны: `.l` после PP, `.p`/`.ast` после parse, `.ir` после IR. После правки — corpus с `#include`/`#define`; эталоны не перезаписывать выводом раннера.

---

**Итого:** 46 / 54 частично (c_base: 38/38 кроме test_25; c_adv: 6× `.pp`+`.ir`+`.l` ⏸; keil: 2/10) · отложено: `test_25`, **`c_adv/`** · **TODO:** keil/ — убрать `artifacts/keil-*` дубликаты · pipeline PP→Lex→Parse→AST→IR

**`reg2051.h` в `.pp`:** полный inline из `tests/src_c/c_adv/_headers/reg2051.h` (не сокращённая выдержка).

**`c_adv/` workflow:** [`tests/src_c/c_adv/GOLDENS.md`](../tests/src_c/c_adv/GOLDENS.md) — всё в дереве `tests/src_c/c_adv/`.

**`keil/` workflow:** [`tests/src_c/keil/README.md`](../tests/src_c/keil/README.md) — всё в дереве `tests/src_c/keil/`.
