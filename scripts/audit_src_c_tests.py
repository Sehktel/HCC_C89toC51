#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Аудит tests/src_c: какие .c имеют эталоны и чего не хватает для прогона."""

from __future__ import annotations

import json
import os
from collections import defaultdict
from dataclasses import dataclass, asdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC_C = ROOT / "tests" / "src_c"
OUT_JSON = ROOT / "artifacts" / "src-c-gaps.json"
OUT_MD = ROOT / "artifacts" / "src-c-gaps.md"
OUT_MATRIX = ROOT / "artifacts" / "src-c-matrix.md"

# Соглашение: tests/src_c/test.txt + раннеры в Haskell
GOLDEN = {
    "preprocessor": ".pp",
    "lexer": ".l",
    "parser": ".p",
    "parser_legacy": ".ast",
    "ir": ".ir",
}

NUMBERED_DIRS = (
    "100_ast",
    "120_parse_negative",
    "200_c51",
    "300_ir",
    "400_lexer",
    "500_preprocessor",
)

RUNNERS = {
    "preprocessor": {"wired": False, "ext": ".pp", "note": "Preprocessor_test — inline; src_c по .pp не подключён"},
    "lexer": {"wired": True, "ext": ".l", "note": "Lexer_test.discoverLexerFixtures"},
    "parser": {"wired": True, "ext": ".p/.ast", "note": "Parser_test.discoverParserFixtures"},
    "ir": {"wired": False, "ext": ".ir", "note": "IR_test — inline; src_c по .ir не подключён"},
}


@dataclass
class CFileReport:
    path: str
    category: str
    name: str
    has_pp: bool
    has_l: bool
    has_p: bool
    has_ast: bool
    has_ir: bool
    missing: list[str]
    partial: bool
    in_numbered_suite: bool
    run_pp: bool
    run_lex: bool
    run_parse: bool
    run_ir: bool


def rel(p: Path) -> str:
    return p.relative_to(ROOT).as_posix()


def category_of(p: Path) -> str:
    parts = p.relative_to(SRC_C).parts
    return parts[0] if parts else "."


def audit() -> dict:
    all_c = sorted(SRC_C.rglob("*.c"))
    reports: list[CFileReport] = []

    for c in all_c:
        has_pp = c.with_suffix(".pp").exists()
        has_l = c.with_suffix(".l").exists()
        has_p = c.with_suffix(".p").exists()
        has_ast = c.with_suffix(".ast").exists()
        has_ir = c.with_suffix(".ir").exists()
        cat = category_of(c)
        in_num = cat in NUMBERED_DIRS

        missing: list[str] = []
        if not has_pp:
            missing.append(".pp")
        if not has_l:
            missing.append(".l")
        if not has_p and not has_ast:
            missing.append(".p")
        if not has_ir:
            missing.append(".ir")

        any_golden = has_pp or has_l or has_p or has_ast or has_ir
        partial = any_golden and bool(missing)

        reports.append(
            CFileReport(
                path=rel(c),
                category=cat,
                name=c.name,
                has_pp=has_pp,
                has_l=has_l,
                has_p=has_p,
                has_ast=has_ast,
                has_ir=has_ir,
                missing=missing,
                partial=partial,
                in_numbered_suite=in_num,
                run_pp=has_pp and RUNNERS["preprocessor"]["wired"],
                run_lex=has_l and RUNNERS["lexer"]["wired"],
                run_parse=(has_p or has_ast) and RUNNERS["parser"]["wired"],
                run_ir=has_ir and RUNNERS["ir"]["wired"],
            )
        )

    no_golden = [r for r in reports if not (r.has_pp or r.has_l or r.has_p or r.has_ast or r.has_ir)]
    partial = [r for r in reports if r.partial]
    numbered = [r for r in reports if r.in_numbered_suite]

    def count_missing(ext: str) -> int:
        key = ext.lstrip(".")
        return sum(1 for r in reports if ext in r.missing)

    by_cat = defaultdict(list)
    for r in no_golden:
        by_cat[r.category].append(r.path)

    summary = {
        "total_c": len(all_c),
        "with_any_golden": len(all_c) - len(no_golden),
        "without_any_golden": len(no_golden),
        "partial_pairs": len(partial),
        "numbered_c_files": len(numbered),
        "missing_counts": {
            ".pp": count_missing(".pp"),
            ".l": count_missing(".l"),
            ".p_or_ast": sum(1 for r in reports if ".p" in r.missing),
            ".ir": count_missing(".ir"),
        },
        "runners": RUNNERS,
    }

    return {
        "summary": summary,
        "golden_extensions": GOLDEN,
        "numbered_dirs": list(NUMBERED_DIRS),
        "no_golden_by_category": {k: v for k, v in sorted(by_cat.items())},
        "partial_pairs": [asdict(r) for r in partial],
        "numbered_gaps": [asdict(r) for r in numbered if r.missing],
        "files": [asdict(r) for r in reports],
    }


def mark(has: bool) -> str:
    return "✓" if has else "—"


def run_mark(active: bool) -> str:
    return "**▶**" if active else "—"


def render_matrix(doc: dict) -> str:
    files: list[dict] = doc["files"]
    s = doc["summary"]

    by_cat: dict[str, list[dict]] = defaultdict(list)
    for f in files:
        by_cat[f["category"]].append(f)

    lines = [
        "# Матрица tests/src_c — эталоны и прогон",
        "",
        "Источник: обход `tests/src_c/**/*.c` · "
        f"файлов `.c`: **{s['total_c']}**",
        "",
        "## Условные обозначения",
        "",
        "| Символ | Значение |",
        "|---|---|",
        "| ✓ | эталонный файл рядом с `.c` **есть** |",
        "| — | эталона **нет** |",
        "| **▶** | cabal test **гоняет** пару (есть эталон + раннер подключён) |",
        "",
        "Эталоны: `.pp` препроцессор · `.l` лексер · `.p`/`.ast` парсер · `.ir` IR.",
        "",
        "## Сводка по каталогам",
        "",
        "| Каталог | .c | .pp | .l | .p | .ast | .ir | ▶PP | ▶Lex | ▶Parse | ▶IR |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]

    def sum_col(rows: list[dict], key: str) -> int:
        return sum(1 for r in rows if r[key])

    grand = {"c": 0, "pp": 0, "l": 0, "p": 0, "ast": 0, "ir": 0, "rpp": 0, "rl": 0, "rp": 0, "rir": 0}
    for cat in sorted(by_cat):
        rows = by_cat[cat]
        n = len(rows)
        grand["c"] += n
        for k, fk in [("pp", "has_pp"), ("l", "has_l"), ("p", "has_p"), ("ast", "has_ast"), ("ir", "has_ir")]:
            grand[k] += sum_col(rows, fk)
        for k, fk in [("rpp", "run_pp"), ("rl", "run_lex"), ("rp", "run_parse"), ("rir", "run_ir")]:
            grand[k] += sum_col(rows, fk)
        lines.append(
            f"| `{cat}/` | {n} | {sum_col(rows, 'has_pp')} | {sum_col(rows, 'has_l')} | "
            f"{sum_col(rows, 'has_p')} | {sum_col(rows, 'has_ast')} | {sum_col(rows, 'has_ir')} | "
            f"{sum_col(rows, 'run_pp')} | {sum_col(rows, 'run_lex')} | {sum_col(rows, 'run_parse')} | "
            f"{sum_col(rows, 'run_ir')} |"
        )
    lines.append(
        f"| **ИТОГО** | **{grand['c']}** | **{grand['pp']}** | **{grand['l']}** | "
        f"**{grand['p']}** | **{grand['ast']}** | **{grand['ir']}** | "
        f"**{grand['rpp']}** | **{grand['rl']}** | **{grand['rp']}** | **{grand['rir']}** |"
    )

    lines.extend(
        [
            "",
            "## Раннеры cabal test (src_c)",
            "",
            "| Стадия | Раннер | src_c подключён |",
            "|---|---|---|",
        ]
    )
    for name, info in s["runners"].items():
        lines.append(f"| {name} | `{info['note']}` | {'да' if info['wired'] else 'нет'} |")

    lines.extend(["", "## Полная матрица по файлам", ""])

    for cat in sorted(by_cat):
        rows = sorted(by_cat[cat], key=lambda r: r["path"])
        lines.append(f"### `{cat}/` ({len(rows)} `.c`)")
        lines.append("")
        lines.append(
            "| `.c` | .pp | .l | .p | .ast | .ir | ▶PP | ▶Lex | ▶Parse | ▶IR |"
        )
        lines.append("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
        for r in rows:
            lines.append(
                f"| `{r['name']}` | {mark(r['has_pp'])} | {mark(r['has_l'])} | "
                f"{mark(r['has_p'])} | {mark(r['has_ast'])} | {mark(r['has_ir'])} | "
                f"{run_mark(r['run_pp'])} | {run_mark(r['run_lex'])} | {run_mark(r['run_parse'])} | "
                f"{run_mark(r['run_ir'])} |"
            )
        lines.append("")

    lines.extend(
        [
            "---",
            "",
            "Обновление: `python scripts/audit_src_c_tests.py` или `just audit-src-c`",
            "",
            "Эталоны создаются **вручную** (не из вывода hcc).",
            "",
        ]
    )
    return "\n".join(lines)


def render_md(doc: dict) -> str:
    s = doc["summary"]
    lines = [
        "# Аудит tests/src_c — эталоны и пробелы",
        "",
        f"Всего `.c`: **{s['total_c']}**",
        "",
        "## Сводка",
        "",
        "| Метрика | Значение |",
        "|---|---:|",
        f"| `.c` с хотя бы одним эталоном | {s['with_any_golden']} |",
        f"| `.c` без эталонов (corpus) | {s['without_any_golden']} |",
        f"| неполные пары (есть эталон, чего-то не хватает) | {s['partial_pairs']} |",
        f"| `.c` в нумерованных каталогах | {s['numbered_c_files']} |",
        "",
        "## Чего не хватает (файлов эталонов)",
        "",
        "| Расширение | Стадия | `.c` без файла |",
        "|---|---|---:|",
        f"| `.pp` | препроцессор | {s['missing_counts']['.pp']} |",
        f"| `.l` | лексер | {s['missing_counts']['.l']} |",
        f"| `.p` / `.ast` | парсер | {s['missing_counts']['.p_or_ast']} |",
        f"| `.ir` | IR | {s['missing_counts']['.ir']} |",
        "",
        "## Раннеры (подключение к cabal test)",
        "",
        "| Стадия | src_c | Примечание |",
        "|---|:---:|---|",
    ]
    for name, info in s["runners"].items():
        wired = "да" if info["wired"] else "**нет**"
        lines.append(f"| {name} | {wired} | {info['note']} |")

    lines.extend(
        [
            "",
            "## Нумерованные каталоги — что дописать в первую очередь",
            "",
            "Каталоги: `" + "`, `".join(doc["numbered_dirs"]) + "`.",
            "",
        ]
    )
    for row in doc["numbered_gaps"]:
        miss = ", ".join(row["missing"])
        lines.append(f"- `{row['path']}` → нет: **{miss}**")

    lines.extend(["", "## Corpus без эталонов (по каталогам)", ""])
    for cat, paths in doc["no_golden_by_category"].items():
        lines.append(f"### `{cat}/` — {len(paths)} файлов")
        lines.append("")
        for p in paths[:8]:
            lines.append(f"- `{p}`")
        if len(paths) > 8:
            lines.append(f"- … ещё {len(paths) - 8}")
        lines.append("")

    lines.extend(
        [
            "## Неполные пары (есть часть эталонов)",
            "",
        ]
    )
    for row in doc["partial_pairs"]:
        have = []
        if row["has_pp"]:
            have.append(".pp")
        if row["has_l"]:
            have.append(".l")
        if row["has_p"]:
            have.append(".p")
        if row["has_ast"]:
            have.append(".ast")
        if row["has_ir"]:
            have.append(".ir")
        miss = ", ".join(row["missing"])
        lines.append(f"- `{row['path']}` есть {', '.join(have) or '—'}; нет: **{miss}**")

    lines.extend(
        [
            "",
            "---",
            "",
            "Сгенерировано: `python scripts/audit_src_c_tests.py`",
            "",
            "**Эталоны (.l/.p/.pp/.ir) пишутся вручную** (Keil, эталонный компилятор,",
            "разбор по стандарту) — не из вывода hcc, иначе тест degenerates в «баг == баг».",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    doc = audit()
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    OUT_MD.write_text(render_md(doc), encoding="utf-8")
    OUT_MATRIX.write_text(render_matrix(doc), encoding="utf-8")
    print(f"OK: {doc['summary']['total_c']} .c -> {OUT_MD}")
    print(f"     matrix -> {OUT_MATRIX}")
    print(f"  partial pairs: {doc['summary']['partial_pairs']}")
    print(f"  numbered gaps: {len(doc['numbered_gaps'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
