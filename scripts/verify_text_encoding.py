from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKED_SUFFIXES = {
    ".dart",
    ".sql",
    ".ts",
    ".py",
    ".md",
    ".yaml",
    ".yml",
    ".json",
    ".html",
    ".css",
    ".txt",
}
SKIP_DIRS = {
    ".dart_tool",
    ".git",
    ".idea",
    "build",
    "android/.gradle",
    "ios/Pods",
    "macos/Flutter/ephemeral",
}
MOJIBAKE_MARKERS = ("Ã", "Â", "â€", "â€”", "â€“", "âœ", "ðŸ")


def should_skip(path: Path) -> bool:
    rel = path.relative_to(ROOT).as_posix()
    if rel == "scripts/verify_text_encoding.py":
        return True
    return any(rel == skipped or rel.startswith(f"{skipped}/") for skipped in SKIP_DIRS)


def main() -> int:
    issues: list[str] = []

    for path in ROOT.rglob("*"):
        if not path.is_file() or should_skip(path) or path.suffix not in CHECKED_SUFFIXES:
            continue

        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError as exc:
            issues.append(f"{path.relative_to(ROOT)}: no es UTF-8 válido ({exc})")
            continue

        for marker in MOJIBAKE_MARKERS:
            if marker in text:
                issues.append(
                    f"{path.relative_to(ROOT)}: posible mojibake detectado ({marker})"
                )
                break

    if issues:
        print("Problemas de texto detectados:")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print("OK: archivos de texto en UTF-8 sin marcadores claros de mojibake.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
