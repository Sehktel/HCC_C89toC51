# Аудит tests/src_c — эталоны и пробелы

Всего `.c`: **79**

## Сводка

| Метрика | Значение |
|---|---:|
| `.c` с хотя бы одним эталоном | 64 |
| `.c` без эталонов (corpus) | 15 |
| неполные пары (есть эталон, чего-то не хватает) | 25 |
| `.c` в нумерованных каталогах | 23 |

## Чего не хватает (файлов эталонов)

| Расширение | Стадия | `.c` без файла |
|---|---|---:|
| `.pp` | препроцессор | 34 |
| `.l` | лексер | 21 |
| `.p` / `.ast` | парсер | 21 |
| `.ir` | IR | 34 |

## Раннеры (подключение к cabal test)

| Стадия | src_c | Примечание |
|---|:---:|---|
| preprocessor | да | Preprocessor_test.discoverPreprocessorFixtures |
| lexer | да | Lexer_test.discoverLexerFixtures |
| parser | да | Parser_test.discoverParserFixtures |
| ir | да | IR_test.discoverIrFixtures |
| hir | **нет** | HighIR_test.discoverHirFixtures (pending) |
| mir | **нет** | MediumIR_test.discoverMirFixtures (pending) |
| lir | **нет** | LowIR_test.discoverLirFixtures (pending) |

## Нумерованные каталоги — что дописать в первую очередь

Каталоги: `100_ast`, `120_parse_negative`, `200_c51`, `300_ir`, `400_lexer`, `500_preprocessor`.

- `tests/src_c/100_ast/test1.c` → нет: **.pp, .ir**
- `tests/src_c/100_ast/test2.c` → нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test3.c` → нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test4.c` → нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test5.c` → нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test6.c` → нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test7.c` → нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test_100_smoke_ast.c` → нет: **.pp, .l, .p, .ir**
- `tests/src_c/120_parse_negative/test_121_switch_body.c` → нет: **.pp, .ir**
- `tests/src_c/120_parse_negative/test_122_do_while_body.c` → нет: **.pp, .ir**
- `tests/src_c/120_parse_negative/test_123_struct_field_decl.c` → нет: **.pp, .ir**
- `tests/src_c/120_parse_negative/test_124_switch_default.c` → нет: **.pp, .ir**
- `tests/src_c/120_parse_negative/test_125_case_chain.c` → нет: **.pp, .ir**
- `tests/src_c/200_c51/test_200_smoke_c51.c` → нет: **.pp, .ir**
- `tests/src_c/200_c51/test_201_c51_sfr_sfr16.c` → нет: **.pp, .ir**
- `tests/src_c/200_c51/test_202_c51_memory_classes.c` → нет: **.pp, .ir**
- `tests/src_c/200_c51/test_203_c51_interrupt_using.c` → нет: **.pp, .ir**
- `tests/src_c/200_c51/test_204_c51_bit_var.c` → нет: **.pp, .ir**
- `tests/src_c/200_c51/test_205_c51_sbit_xor.c` → нет: **.pp, .ir**
- `tests/src_c/200_c51/test_206_c51_reentrant_fn.c` → нет: **.pp, .ir**
- `tests/src_c/300_ir/test_300_smoke_ir.c` → нет: **.pp, .l, .p, .ir**
- `tests/src_c/400_lexer/test_400_smoke_lexer.c` → нет: **.pp, .l, .p, .ir**
- `tests/src_c/500_preprocessor/test_500_smoke_preprocessor.c` → нет: **.pp, .l, .p, .ir**

## Corpus без эталонов (по каталогам)

### `100_ast/` — 1 файлов

- `tests/src_c/100_ast/test_100_smoke_ast.c`

### `300_ir/` — 1 файлов

- `tests/src_c/300_ir/test_300_smoke_ir.c`

### `400_lexer/` — 1 файлов

- `tests/src_c/400_lexer/test_400_smoke_lexer.c`

### `500_preprocessor/` — 1 файлов

- `tests/src_c/500_preprocessor/test_500_smoke_preprocessor.c`

### `c_base/` — 1 файлов

- `tests/src_c/c_base/test_25_singleton_guard.c`

### `examples/` — 2 файлов

- `tests/src_c/examples/blink.c`
- `tests/src_c/examples/simple.c`

### `keil/` — 8 файлов

- `tests/src_c/keil/0_blink_0/blink.c`
- `tests/src_c/keil/0_blink_0_1/blink.c`
- `tests/src_c/keil/0_declare_0/declare.c`
- `tests/src_c/keil/0_int0_0/int0.c`
- `tests/src_c/keil/0_int_0/0_interrupt_0.c`
- `tests/src_c/keil/0_int_0_1/0_int_0.c`
- `tests/src_c/keil/0_int_f_0/int_f.c`
- `tests/src_c/keil/0_test_0/test.c`

## Неполные пары (есть часть эталонов)

- `tests/src_c/100_ast/test1.c` есть .l, .p, .ast; нет: **.pp, .ir**
- `tests/src_c/100_ast/test2.c` есть .ast; нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test3.c` есть .ast; нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test4.c` есть .ast; нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test5.c` есть .ast; нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test6.c` есть .ast; нет: **.pp, .l, .ir**
- `tests/src_c/100_ast/test7.c` есть .p; нет: **.pp, .l, .ir**
- `tests/src_c/120_parse_negative/test_121_switch_body.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/120_parse_negative/test_122_do_while_body.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/120_parse_negative/test_123_struct_field_decl.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/120_parse_negative/test_124_switch_default.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/120_parse_negative/test_125_case_chain.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/200_c51/test_200_smoke_c51.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/200_c51/test_201_c51_sfr_sfr16.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/200_c51/test_202_c51_memory_classes.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/200_c51/test_203_c51_interrupt_using.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/200_c51/test_204_c51_bit_var.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/200_c51/test_205_c51_sbit_xor.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/200_c51/test_206_c51_reentrant_fn.c` есть .l, .p; нет: **.pp, .ir**
- `tests/src_c/c_adv/main_test/main_test.c` есть .pp, .l, .ir; нет: **.p**
- `tests/src_c/c_adv/test_bit_operations/test_bit_operations.c` есть .pp, .l, .ir; нет: **.p**
- `tests/src_c/c_adv/test_interrupt_setup/test_interrupt_setup.c` есть .pp, .l, .ir; нет: **.p**
- `tests/src_c/c_adv/test_memory_types/test_memory_types.c` есть .pp, .l, .ir; нет: **.p**
- `tests/src_c/c_adv/test_port_operations/test_port_operations.c` есть .pp, .l, .ir; нет: **.p**
- `tests/src_c/c_adv/test_timer_operations/test_timer_operations.c` есть .pp, .l, .ir; нет: **.p**

---

Сгенерировано: `python scripts/audit_src_c_tests.py`

**Эталоны (.l/.p/.pp/.ir) пишутся вручную** (Keil, эталонный компилятор,
разбор по стандарту) — не из вывода hcc, иначе тест degenerates в «баг == баг».
