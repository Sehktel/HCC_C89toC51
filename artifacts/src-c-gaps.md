# Аудит tests/src_c — эталоны и пробелы

Всего `.c`: **79**

## Сводка

| Метрика | Значение |
|---|---:|
| `.c` с хотя бы одним эталоном | 76 |
| `.c` без эталонов (corpus) | 3 |
| неполные пары (есть эталон, чего-то не хватает) | 6 |
| `.c` в нумерованных каталогах | 23 |

## Чего не хватает (файлов эталонов)

| Расширение | Стадия | `.c` без файла |
|---|---|---:|
| `.pp` | препроцессор | 3 |
| `.l` | лексер | 3 |
| `.p` / `.ast` | парсер | 9 |
| `.ir` | IR | 3 |

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


## Corpus без эталонов (по каталогам)

### `c_base/` — 1 файлов

- `tests/src_c/c_base/test_25_singleton_guard.c`

### `examples/` — 2 файлов

- `tests/src_c/examples/blink.c`
- `tests/src_c/examples/simple.c`

## Неполные пары (есть часть эталонов)

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
