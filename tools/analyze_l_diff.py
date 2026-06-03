#!/usr/bin/env python3
"""Сравнение lexerPure(.pp) с эталоном .l для одного fixture."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def lex_pp(pp_text: str) -> str:
    # однострочный ghc -e через cabal exec
    cmd = [
        "cabal", "exec", "--", "ghc", "-isrc", "-e",
        f"import Lexer (lexerPure); putStr (show (lexerPure {pp_text!r}))",
    ]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=True)
    return r.stdout.strip()


def trim(s: str) -> str:
    return s.strip()


def first_diff(a: str, b: str) -> tuple[int, str, str] | None:
    n = min(len(a), len(b))
    for i in range(n):
        if a[i] != b[i]:
            return i, a[max(0, i - 60) : i + 80], b[max(0, i - 60) : i + 80]
    if len(a) != len(b):
        return n, a[max(0, n - 60) :], b[max(0, n - 60) :]
    return None


def fix_macro_parens(l: str) -> str:
    return re.sub(
        r"(TokenLessLess,TokenLeftParen,TokenNumber \d+,TokenRightParen),TokenRightParen,TokenSemicolon",
        r"\1,TokenRightParen,TokenRightParen,TokenSemicolon",
        l,
    )


def fix_bit_init(l: str) -> str:
    # bit name; -> bit name = 0;  (только если в .pp есть = 0)
    return re.sub(
        r"(TokenBit,TokenIdentifier \"[^\"]+\"),TokenSemicolon",
        r"\1,TokenAssign,TokenNumber 0,TokenSemicolon",
        l,
    )


def main() -> None:
    name = sys.argv[1] if len(sys.argv) > 1 else "test_port_operations"
    base = ROOT / "tests/src_c/c_adv" / name / name
    pp = base.with_suffix(".pp").read_text(encoding="utf-8")
    act = lex_pp(pp)
    exp = trim(base.with_suffix(".l").read_text(encoding="utf-8"))
    print(f"{name}: act={len(act)} exp={len(exp)}")
    d = first_diff(act, exp)
    if d:
        i, ac, ex = d
        print(f"first diff @{i}")
        print("ACT:", ac)
        print("EXP:", ex)
    else:
        print("MATCH")


if __name__ == "__main__":
    main()
