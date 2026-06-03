# Гlossary — термины проекта

> Статус: **draft** · Литеры ЕСПД — **назначим позже**

| Термин | Определение |
|--------|-------------|
| **Фронтенд** | Стадии 1–4: PP → Lex → Parse → AST. Закрытый контур текущей итерации |
| **Parser.Ast** | Синтаксическое дерево (`Parser.hs`) — «как записано по грамматике» |
| **AST** | Семантическое дерево (`AST.hs`) — «какие сущности программы» |
| **fromParserAst** | Единственный мост Parser.Ast → AST |
| **Golden / эталон** | Файл ожидаемого выхода (`.pp`, `.l`, `.p`, `.ir`) рядом с `.c` |
| **post-PP** | Текст после препроцессора; вход лексера |
| **Legacy IR** | Suite `test-ir`, golden `.ir` — **до слияния** с High IR |
| **High IR (HIR)** | Suite `test-high-ir`, golden `.hir` — **раздельно** от legacy IR; слияние запланировано |
| **Codegen** | Стадия 10 — отдельная от Low IR |
| **Fail-fast** | PP: IO error на битый include; Parser: `AstUnknown` без падения процесса |
| **src_c** | Корpus `tests/src_c/` |
| **TestMatrix** | JSON/HTML матрица результатов; сбор через `shouldBeRecorded` |
| **shouldBeRecorded** | подстановка expected/actual + запись в matrix + assert |
| **discover*Fixtures** | авто-подстановка кейсов из `src_c` по golden ext |
| **Logger** | уровневый лог (`Logger.hs`); `silentLogger` в тестах |
| **lexerPure / parseTokensPure** | без лога; канон для golden |
| **Manifest** | `tests/test-manifest.json` — декларативные cases + expectation |
| **AstUnknown / ASTUnknown** | Маркеры неполного разбора на стадиях 3–4 |
