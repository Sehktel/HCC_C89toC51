# c_adv/ — ручные эталоны (рядом с `.c`)

**Всё здесь**, в `tests/src_c/c_adv/`. Без PowerShell-glue, без `artifacts/c_adv-bodies/`.

## Дерево

```
c_adv/
  golden-manifest.json       # какой prefix у какого .c (справочник)
  _headers/                  # исходные заголовки для #include и Keil-сборки
    common.h
    reg2051.h
  _prefix/                   # общий post-PP фрагмент (reg2051 + common.h)
    common-prefix.{pp,l}
  main_test/
    main_test.c
    main_test.body.{pp,l}    # опционально: только код после PP
    main_test.{pp,l,ir}      # финальные эталоны (полные, для cabal test)
  test_bit_operations/
    …
  compiler_options.json        # справочник Keil (без раннера)
  README.md
```

## Workflow (только руками)

1. Post-PP тело → `<stem>.body.pp` или сразу полный `<stem>.pp`.
2. Все `.c` включают `"common.h"` → в **полном** `<stem>.pp` inline из `_prefix/common-prefix.pp` + код из `.c` после PP. **Склеивать в редакторе**, не скриптом.
3. `.l` — токены post-PP; при include: токены из `_prefix/common-prefix.l` + тело в `[…]`.
4. `.p` / `.ast` — AST post-PP (ещё не готовы для c_adv).
5. `.ir` — по правилу проекта.
6. `just audit-src-c` · `cabal test …` — смотреть diff, **не** перезаписывать эталон выводом раннера.

## Справочник prefix

`golden-manifest.json`: все 6 фикстур используют `common-prefix` (`reg2051.h` + `common.h` после препроцессора).

## Pipeline (канон)

`.c` → PP → `.pp` → Lex → `.l` → Parse → `.p`/`.ast` → IR → `.ir`

Раннеры пока Lex/Parse на сыром `.c` — см. `artifacts/src-c-manual-goldens-todo.md`.

## Прогресс

`artifacts/src-c-manual-goldens-todo.md` (секция c_adv/).
