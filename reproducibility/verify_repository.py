#!/usr/bin/env python3
"""Check the research repository without fitting models or changing files.

Uses only the Python standard library and Git. The migration manifest is the
baseline for published data/figures; it is not a claim of statistical replication.
Run from any directory: python reproducibility/verify_repository.py
"""

from __future__ import annotations

import ast
import csv
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "reproducibility/path_migration.csv"
UPDATES = ROOT / "reproducibility/artifact_updates.csv"
PROTECTED_SUFFIXES = {
    ".csv", ".xlsx", ".docx", ".eps", ".png", ".svg", ".pptx",
    ".gpkg", ".graph", ".json",
}
LEGACY_DIRECTORIES = (
    "CODIGO/", "COVARIABLES/", "DATOS_ENSANUT/", "DATOS_GEO_MEXICO/",
    "RESULTADOS/", "TABLAS/", "FIGURAS/", "SUPLEMENTARIO/",
)
ERRORS: list[str] = []
COUNTS: dict[str, int] = {}


def error(message: str) -> None:
    ERRORS.append(message)


def git(*args: str, input_text: str | None = None) -> str:
    result = subprocess.run(
        ["git", "-c", "core.quotepath=false", *args], cwd=ROOT,
        input=input_text, text=True, encoding="utf-8", errors="strict",
        capture_output=True, check=False,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Git command failed")
    return result.stdout


def exact_path(relative: str) -> Path | None:
    """Check path spelling component by component, including on Windows."""
    parsed = PurePosixPath(relative)
    if (not relative or "\\" in relative or parsed.is_absolute()
            or ".." in parsed.parts or re.match(r"^[A-Za-z]:", relative)):
        error(f"Unsafe or nonportable repository path: {relative!r}")
        return None
    current = ROOT
    for part in parsed.parts:
        if not current.is_dir():
            error(f"Missing parent directory: {relative}")
            return None
        names = {entry.name for entry in current.iterdir()}
        if part not in names:
            near = next((name for name in names if name.casefold() == part.casefold()), None)
            detail = f" (case mismatch: expected {part!r}, found {near!r})" if near else ""
            error(f"Missing path: {relative}{detail}")
            return None
        current = current / part
    if not current.is_file():
        error(f"Expected a regular file: {relative}")
        return None
    if not current.resolve().is_relative_to(ROOT):
        error(f"Repository path resolves outside the repository: {relative}")
        return None
    return current


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def check_manifest() -> set[str]:
    with MANIFEST.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        required = {"previous_path", "current_path", "sha256_before_migration"}
        if not required.issubset(reader.fieldnames or []):
            raise ValueError("Migration manifest lacks required columns")
        rows = list(reader)
    if not rows:
        raise ValueError("Migration manifest is empty")
    updates: dict[str, dict[str, str]] = {}
    if UPDATES.exists():
        with UPDATES.open(encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream)
            if not {"path", "sha256_before", "sha256_after", "reason"}.issubset(reader.fieldnames or []):
                raise ValueError("Artifact update manifest lacks required columns")
            for row in reader:
                name = row["path"]
                if name in updates:
                    error(f"Duplicate documented artifact update: {name}")
                if not row["reason"].strip():
                    error(f"Artifact update lacks an explanation: {name}")
                for key in ("sha256_before", "sha256_after"):
                    if not re.fullmatch(r"[0-9a-fA-F]{64}", row[key]):
                        error(f"Invalid {key} for documented artifact update: {name}")
                updates[name] = row
    previous: set[str] = set()
    destinations: set[str] = set()
    protected_paths: set[str] = set()
    checked = 0
    unchanged = 0
    for row in rows:
        old, new, expected = (row[name] for name in
                              ("previous_path", "current_path", "sha256_before_migration"))
        if old in previous or new in destinations:
            error(f"Duplicate migration source or destination: {old} -> {new}")
        previous.add(old)
        destinations.add(new)
        if not re.fullmatch(r"[0-9a-fA-F]{64}", expected):
            error(f"Invalid SHA-256 in manifest: {new}")
        path = exact_path(new)
        protected = (PurePosixPath(old).suffix.lower() in PROTECTED_SUFFIXES
                     or PurePosixPath(new).suffix.lower() in PROTECTED_SUFFIXES
                     or old == "docs/index.html" or new == "docs/index.html")
        if protected:
            protected_paths.add(new)
        if path and protected:
            checked += 1
            actual = sha256(path)
            if new in updates:
                update = updates[new]
                if update["sha256_before"].lower() != expected.lower():
                    error(f"Artifact update does not identify the original baseline hash: {new}")
                if update["sha256_after"].lower() != actual:
                    error(f"Artifact update does not match the current artifact hash: {new}")
                if actual == expected.lower():
                    error(f"Artifact update is unnecessary; artifact matches original baseline: {new}")
            elif actual != expected.lower():
                error(f"Published artifact differs from migration baseline: {new}")
            else:
                unchanged += 1
    for name in sorted(set(updates) - protected_paths):
        error(f"Orphan artifact update; path is not a protected migration destination: {name}")
    COUNTS["manifest destinations"] = len(rows)
    COUNTS["protected-artifact hash checks"] = checked
    COUNTS["artifacts unchanged from migration baseline"] = unchanged
    COUNTS["documented artifact updates"] = len(updates)
    return destinations


def current_public_files() -> set[str]:
    """Use current files, including not-yet-staged moves, rather than an old index."""
    names = git("ls-files", "--cached", "--others", "--exclude-standard", "-z").split("\0")
    paths = {name for name in names if name and (ROOT / name).is_file()}
    for name in sorted(paths):
        exact_path(name)
    COUNTS["current tracked or unignored files"] = len(paths)
    return paths


def remove_r_comments(text: str) -> str:
    output: list[str] = []
    quote: str | None = None
    escaped = False
    in_comment = False
    for char in text:
        if in_comment:
            if char == "\n":
                in_comment = False
                output.append(char)
            continue
        if quote:
            output.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in ('"', "'", "`"):
            quote = char
            output.append(char)
        elif char == "#":
            in_comment = True
        else:
            output.append(char)
    return "".join(output)


def check_sources(paths: set[str]) -> None:
    source_count = 0
    python_count = 0
    for name in sorted(paths):
        path = ROOT / name
        if path.suffix.lower() == ".r":
            active = remove_r_comments(path.read_text(encoding="utf-8-sig"))
            for match in re.finditer(r"\bsource\s*\(\s*(['\"])(.*?)\1", active, re.DOTALL):
                exact_path(match.group(2))
                source_count += 1
            for match in re.finditer(r"(['\"])(.*?)\1", active, re.DOTALL):
                literal = match.group(2)
                if literal.startswith(LEGACY_DIRECTORIES) or re.match(r"^[A-Za-z]:[/\\]", literal):
                    error(f"Legacy or absolute R path in {name}: {literal}")
            if name == "RUN_ALL.R":
                for script in set(re.findall(r"['\"]([0-9]{2}[a-z]?_[^'\"\n]+\.R)['\"]", active)):
                    exact_path("analysis/" + script)
                    source_count += 1
        elif path.suffix == ".py":
            try:
                tree = ast.parse(path.read_text(encoding="utf-8-sig"), filename=name)
            except SyntaxError as exc:
                error(f"Python syntax error in {name}: {exc}")
                continue
            python_count += 1
            # The public HTML builder reads constant paths with io.open().
            if name == "analysis/25_explorador_html.py":
                for node in ast.walk(tree):
                    if not isinstance(node, ast.Call) or not node.args:
                        continue
                    function = node.func
                    is_open = ((isinstance(function, ast.Name) and function.id == "open")
                               or (isinstance(function, ast.Attribute) and function.attr == "open"))
                    if not is_open or not isinstance(node.args[0], ast.Constant):
                        continue
                    literal = node.args[0].value
                    mode = node.args[1].value if len(node.args) > 1 and isinstance(node.args[1], ast.Constant) else "r"
                    mode = next((kw.value.value for kw in node.keywords if kw.arg == "mode"
                                 and isinstance(kw.value, ast.Constant)), mode)
                    if isinstance(literal, str) and isinstance(mode, str) and not any(c in mode for c in "wax+"):
                        exact_path(literal)
                        source_count += 1
    COUNTS["static script/input references"] = source_count
    COUNTS["Python syntax checks"] = python_count


def check_site() -> None:
    data_text = (ROOT / "docs/datos.json").read_text(encoding="utf-8")
    translations_text = (ROOT / "analysis/i18n_explorador.json").read_text(encoding="utf-8")
    template = (ROOT / "analysis/plantilla_explorador.html").read_text(encoding="utf-8")
    data, translations = json.loads(data_text), json.loads(translations_text)
    if data.get("n_muni") != len(data.get("munis", [])):
        error("Explorer municipality count does not match its payload")
    if set(translations.get("es", {})) != set(translations.get("en", {})):
        error("Explorer translation keys differ between Spanish and English")
    if template.count("/*__DATOS__*/") != 1 or template.count("/*__I18N__*/") != 1:
        error("Explorer template must have one data marker and one translation marker")
    expected = template.replace("/*__DATOS__*/", data_text.replace("</", "<\\/"))
    expected = expected.replace("/*__I18N__*/", translations_text)
    if expected != (ROOT / "docs/index.html").read_text(encoding="utf-8"):
        error("Published explorer HTML does not match its JSON, translations and template")
    COUNTS["explorer municipalities"] = len(data.get("munis", []))


def check_private_files(paths: set[str]) -> None:
    known_private = re.compile(
        r"(^|/)(base_analitica[^/]*|ponderador_calibrado[^/]*|LEEME_CORRESPONDENCIA[^/]*"
        r"|_MD_[^/]*|DECLARACION_[^/]*|DJ_[^/]*|PARA_[^/]*\.zip)$", re.IGNORECASE,
    )
    for name in sorted(paths):
        path = PurePosixPath(name)
        if (known_private.search(name) or path.suffix.lower() == ".rds"
                or any(part.startswith("0_ENVIO") or part in {".venv", "_TRABAJO_INTERNO", "private"}
                       for part in path.parts)
                or (name.startswith("data/raw/") and path.name not in {"README.md", ".gitkeep"})):
            error(f"Private/raw artifact is tracked or not ignored: {name}")
        if path.suffix.lower() == ".csv":
            with (ROOT / name).open(encoding="utf-8-sig", errors="replace", newline="") as stream:
                header = next(csv.reader(stream), [])
            if {column.upper().strip() for column in header} & {"FOLIO_I", "FOLIO_INT"}:
                error(f"Public CSV contains individual linkage identifiers: {name}")

    # These paths need not exist. Check the migrated rules before anybody copies
    # local data into a clean clone and accidentally stages it.
    private_examples = [
        "data/raw/ensanut/2024/adultos_ensanut2024_w.dta",
        "results/estimates/base_analitica_adultos_2021_2024.csv",
        "results/estimates/ponderador_calibrado.csv",
        "results/estimates/modelo_FINAL_AWARE_ESH.rds",
        "LEEME_CORRESPONDENCIA.txt",
        "_MD_BREVE.md",
        "0_ENVIO_SPM/MANUSCRITO_SPM.docx",
    ]
    result = subprocess.run(
        ["git", "check-ignore", "--no-index", "--stdin", "-z"], cwd=ROOT,
        input="\0".join(private_examples) + "\0", text=True, encoding="utf-8",
        capture_output=True, check=False,
    )
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr.strip() or "Cannot check private-path ignore rules")
    ignored = set(result.stdout.split("\0"))
    for name in private_examples:
        if name not in ignored:
            error(f"Ignore rules do not protect a known private path: {name}")
    COUNTS["private-path ignore checks"] = len(private_examples)


def main() -> int:
    try:
        manifest_paths = check_manifest()
        public_paths = current_public_files()
        omitted = manifest_paths - public_paths
        for name in sorted(omitted):
            error(f"Migration destination is absent from the current publication candidates: {name}")
        check_sources(public_paths)
        check_site()
        check_private_files(public_paths)
    except (OSError, ValueError, RuntimeError, KeyError, csv.Error) as exc:
        error(str(exc))
    for label, count in COUNTS.items():
        print(f"CHECK {label}: {count}")
    for message in ERRORS:
        print("FAIL " + message)
    print("LIMIT: static paths, current publication candidates, artifact hashes and site consistency only.")
    print("LIMIT: no INLA refit, external-input validation, R execution, editorial approval or Git-history scan.")
    print("LIMIT: aggregate small-cell disclosure policy is not assessed by this individual-file check.")
    print("FAIL" if ERRORS else "PASS")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    raise SystemExit(main())
