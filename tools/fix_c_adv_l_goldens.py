#!/usr/bin/env python3
"""Синхронизация .l goldens в c_adv/ с соответствующими .pp.

Сопутствующие утилиты (tools/):
  check_l_goldens.exe  — OK/FAIL по всем c_adv/*.pp vs .l
  inspect_diff.exe     — первое расхождение act/exp с контекстом
  find_needle.exe      — позиция result|= и READ_BIT if в bit_operations
  lex_snippets.hs      — токенизация коротких фрагментов макросов
  slice_diff.hs        — контекст вокруг заданного индекса (base, idx)

Запуск: python tools/fix_c_adv_l_goldens.py && tools/check_l_goldens.exe
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "tests/src_c/c_adv"


def fix_set_toggle_parens(s: str) -> str:
    """SET_BIT/TOGGLE_BIT: ((reg) op= (1 << (bit)));"""
    return re.sub(
        r"(TokenLessLess,TokenLeftParen,TokenNumber \d+,TokenRightParen),TokenRightParen,TokenSemicolon",
        r"\1,TokenRightParen,TokenRightParen,TokenSemicolon",
        s,
    )


def fix_clear_parens(s: str) -> str:
    """CLEAR_BIT: ((reg) &= (~(1 << (bit))));"""
    return re.sub(
        r"(TokenTilde,TokenLeftParen,TokenNumber 1,TokenLessLess,TokenLeftParen,TokenNumber \d+,TokenRightParen),TokenRightParen,TokenRightParen,TokenSemicolon",
        r"\1,TokenRightParen,TokenRightParen,TokenRightParen,TokenSemicolon",
        s,
    )


def fix_read_parens(s: str) -> str:
    """READ_BIT: if (((reg) & (1 << (bit)))) — ровно 4 ')' перед result."""
    # было 3 ')' — добавляем одну
    s = re.sub(
        r'(TokenAmpersand,TokenLeftParen,TokenNumber 1,TokenLessLess,TokenLeftParen,TokenNumber \d+,TokenRightParen),TokenRightParen,TokenRightParen,TokenIdentifier "result"',
        r'\1,TokenRightParen,TokenRightParen,TokenRightParen,TokenIdentifier "result"',
        s,
    )
    # было 5 ')' (переисправление) — убираем лишнюю
    s = re.sub(
        r'(TokenAmpersand,TokenLeftParen,TokenNumber 1,TokenLessLess,TokenLeftParen,TokenNumber \d+,TokenRightParen),TokenRightParen,TokenRightParen,TokenRightParen,TokenRightParen,TokenIdentifier "result"',
        r'\1,TokenRightParen,TokenRightParen,TokenRightParen,TokenIdentifier "result"',
        s,
    )
    # артефакт прошлой версии скрипта
    return s.replace('TokenIdentifier \\"result\\"', 'TokenIdentifier "result"')


def fix_timer_return(s: str) -> str:
    """return ((unsigned int)high_byte << 8) | low_byte;"""
    s = s.replace(
        "TokenReturn,TokenLeftParen,TokenLeftParen,TokenLeftParen,TokenUnsigned",
        "TokenReturn,TokenLeftParen,TokenLeftParen,TokenUnsigned",
    )
    # лишняя ')' перед ';' после low_byte
    return s.replace(
        'TokenIdentifier "low_byte",TokenRightParen,TokenSemicolon',
        'TokenIdentifier "low_byte",TokenSemicolon',
    )


def fix_bit_init(s: str, name: str) -> str:
    old = f'TokenBit,TokenIdentifier "{name}",TokenSemicolon'
    new = f'TokenBit,TokenIdentifier "{name}",TokenAssign,TokenNumber 0,TokenSemicolon'
    return s.replace(old, new)


SPECS: dict[str, dict] = {
    "test_timer_operations": {
        "bits": ["timer0_flag", "timer1_flag"],
        "timer_return": True,
    },
    "test_port_operations": {"bits": ["port_test_flag"]},
    "test_bit_operations": {"bits": []},
    "test_memory_types": {"bits": []},
    "test_interrupt_setup": {"bits": []},
}


def fix_file(name: str, spec: dict) -> bool:
    path = ROOT / name / f"{name}.l"
    original = path.read_text(encoding="utf-8").strip()
    updated = fix_set_toggle_parens(original)
    updated = fix_clear_parens(updated)
    updated = fix_read_parens(updated)
    if spec.get("timer_return"):
        updated = fix_timer_return(updated)
    for bit in spec.get("bits", []):
        updated = fix_bit_init(updated, bit)
    if updated != original:
        path.write_text(updated + "\n", encoding="utf-8")
    return updated != original


def main() -> None:
    for name, spec in SPECS.items():
        changed = fix_file(name, spec)
        print(("updated " if changed else "ok      ") + name)


if __name__ == "__main__":
    main()
