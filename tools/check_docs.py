"""저장소 Markdown의 상대 링크와 heading anchor가 존재하는지 검사한다. 표준 라이브러리만 사용한다."""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKIP = {".git", ".godot", "build", "android"}


def slug(heading: str) -> str:
    """GitHub heading anchor 규칙의 근사치: 소문자, 기호 제거, 공백→하이픈."""
    text = re.sub(r"[`*_]", "", heading.strip().lower())
    text = re.sub(r"[^\w\- ]", "", text, flags=re.UNICODE)
    return text.replace(" ", "-")


def anchors(path: pathlib.Path) -> set:
    content = path.read_text(encoding="utf-8")
    content = re.sub(r"```.*?```", "", content, flags=re.S)
    return {slug(match) for match in re.findall(r"^#+\s+(.*)$", content, re.M)}


def main() -> int:
    files = [p for p in ROOT.rglob("*.md") if not SKIP.intersection(p.relative_to(ROOT).parts)]
    errors = []
    for path in files:
        content = re.sub(r"```.*?```", "", path.read_text(encoding="utf-8"), flags=re.S)
        for link in re.findall(r"\]\(([^)\s]+)\)", content):
            if re.match(r"^[a-z]+:", link):
                continue
            target, _, anchor = link.partition("#")
            resolved = (path.parent / target).resolve() if target else path
            if not resolved.exists():
                errors.append(f"{path.relative_to(ROOT)}: missing {link}")
            elif anchor and resolved.suffix == ".md" and anchor not in anchors(resolved):
                errors.append(f"{path.relative_to(ROOT)}: missing anchor {link}")
    for error in errors:
        print(error)
    print(f"Checked {len(files)} Markdown files, {len(errors)} broken links")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
