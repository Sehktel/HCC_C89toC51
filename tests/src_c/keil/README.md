# keil/ — ручные эталоны (рядом с `.c`)

**Полный workflow:** [`artifacts/src-c-golden-workflow.md`](../../../artifacts/src-c-golden-workflow.md)

**Всё здесь**, в `tests/src_c/keil/`. Без PowerShell, без dump lexer/parser в эталоны.

## Дерево

```
keil/
  golden-manifest.json     # какой prefix у какого .c (справочник)
  _prefix/                 # общие фрагменты заголовков (копировать руками)
    reg2051.{pp,l,p}
    reg51.{pp,l,p}
  test1/
    test1.c
    test1.{pp,l,p,ast,ir}
  test2/
    test2.c
    test2.body.{pp,l,p}    # опционально: черновик только кода (без reg2051)
    test2.{pp,l,p,ast,ir}  # финальные эталоны (полные, для cabal test)
  0_blink_0/
    blink.c
    blink.{pp,l,p,ast,ir}
  …
```

## Workflow (только руками)

1. Post-PP тело файла → `<stem>.body.pp` или сразу полный `<stem>.pp`.
2. Если `#include <reg2051.h>` / `<reg51.h>`: в **полном** `<stem>.pp` — inline из `_prefix/reg2051.pp` (или `reg51.pp`) + код из `.c` после PP. **Склеивать в редакторе**, не скриптом.
3. `.l` — токены post-PP текста; при include: токены из `_prefix/reg2051.l` + тело (в `[…]`).
4. `.p` / `.ast` — AST post-PP; при include: `AstDeclaration …` из `_prefix/reg2051.p` + `AstFunctionDef …` тела внутри `AstProgram […]`.
5. `.ir` — по правилу проекта (`[IrUnknown]` и т.д.).
6. `just audit-src-c` · `cabal test …` — смотреть diff, **не** перезаписывать эталон выводом раннера.

## Справочник prefix

`golden-manifest.json`: `relDir`, `stem`, `prefix` (`none` | `reg2051` | `reg51`).

## Pipeline (канон)

`.c` → PP → `.pp` → Lex → `.l` → Parse → `.p`/`.ast` → IR → `.ir`

Раннеры пока Lex/Parse на сыром `.c` — см. `artifacts/src-c-manual-goldens-todo.md`.

## Прогресс

`artifacts/src-c-manual-goldens-todo.md` (секция keil/).
