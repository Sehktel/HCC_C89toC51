#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Рендер markdown-таблицы из artifacts/test-matrix.json (точка правды после cabal test)."""

from __future__ import annotations

import json
import os
import sys
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MATRIX = ROOT / "artifacts" / "test-matrix.json"
OUT_MD = ROOT / "artifacts" / "all-tests-table.md"
# Макс. длина фрагмента в ячейке до вставки <br> (переопределяется TEST_TABLE_WRAP).
DEFAULT_WRAP = 56


def esc_cell(s: str) -> str:
    s = str(s).replace("\r\n", "\n").replace("\r", "\n")
    s = s.replace("|", "\\|")
    return s.replace("\n", "<br>")


def wrap_cell(s: str, width: int) -> str:
    """Перенос длинных ячеек: сначала по запятым (списки токенов/AST), иначе по ширине."""
    if width <= 0 or len(s) <= width:
        return s
    if "," in s:
        parts: list[str] = []
        chunk = ""
        for i, piece in enumerate(s.split(",")):
            segment = piece if i == 0 else "," + piece
            if chunk and len(chunk) + len(segment) > width:
                parts.append(chunk + ",")
                chunk = piece
            else:
                chunk = chunk + segment if chunk else piece
        if chunk:
            parts.append(chunk)
        if len(parts) > 1:
            return "<br>".join(parts)
    return "<br>".join(
        textwrap.wrap(s, width=width, break_long_words=True, break_on_hyphens=False)
    )


def status_note(status: str, note: str) -> str:
    base = {"pass": "OK (прогон)", "fail": "FAIL", "pending": "PENDING"}.get(status, status)
    if note:
        return f"{base}; {note}"
    return base


def load_matrix(path: Path) -> dict:
    if not path.is_file():
        raise FileNotFoundError(
            f"Нет {path}. Сначала: cabal test test-web-report  (или just test-web-report)"
        )
    return json.loads(path.read_text(encoding="utf-8"))


def cell(s: object, wrap_width: int, do_wrap: bool = False) -> str:
    text = esc_cell(s)
    return wrap_cell(text, wrap_width) if do_wrap else text


def render_md(doc: dict, wrap_width: int) -> str:
    entries = doc.get("entries", [])
    lines = [
        "# Полная таблица тестов HCC C89→C51",
        "",
        f"Источник: `{doc.get('matrixPath', 'artifacts/test-matrix.json')}` · "
        f"сгенерировано: `{doc.get('generatedAt', '?')}` · "
        f"строк: **{len(entries)}** · "
        f"перенос ячеек: **{wrap_width}** симв.",
        "",
        "Колонки **Вход / Ожидание / Выход** — факты прогона Haskell (`TestMatrix`).",
        "",
        "<style>",
        "table { table-layout: fixed; width: 100%; }",
        "th:nth-child(4), td:nth-child(4),",
        "th:nth-child(5), td:nth-child(5),",
        "th:nth-child(6), td:nth-child(6) {",
        "  word-break: break-word; overflow-wrap: anywhere; vertical-align: top; font-size: 90%;",
        "}",
        "</style>",
        "",
        "| № | Набор | Имя теста | Вход | Ожидание | Выход | Статус | Примечание |",
        "|---:|---|---|---|---|---|---|---|",
    ]
    for i, e in enumerate(entries, 1):
        st = e.get("status", "")
        note = status_note(st, e.get("note", ""))
        lines.append(
            f"| {i} | {cell(e.get('suite', ''), wrap_width)} | "
            f"{cell(e.get('name', ''), wrap_width)} | "
            f"{cell(e.get('input', ''), wrap_width, True)} | "
            f"{cell(e.get('expected', ''), wrap_width, True)} | "
            f"{cell(e.get('actual', ''), wrap_width, True)} | "
            f"{cell(st, wrap_width)} | {cell(note, wrap_width)} |"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    matrix_path = Path(os.environ.get("TEST_MATRIX", str(DEFAULT_MATRIX)))
    if len(sys.argv) > 1:
        matrix_path = Path(sys.argv[1])
    out_path = Path(os.environ.get("TEST_TABLE_MD", str(OUT_MD)))
    wrap_width = int(os.environ.get("TEST_TABLE_WRAP", str(DEFAULT_WRAP)))
    doc = load_matrix(matrix_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(render_md(doc, wrap_width), encoding="utf-8")
    print(f"OK: {len(doc.get('entries', []))} rows -> {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
