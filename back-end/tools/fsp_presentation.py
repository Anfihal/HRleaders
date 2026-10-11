"""Generate the FSP presentation of a repository from Git facts and the FSP template.

Pipeline of issue #8: Git data extraction -> repo_stats -> template inspection ->
slide specification -> assembly (text of reviewed regions only) -> structural QA.
Visual QA lives in ``tools.fsp_visual_qa`` because it needs a PPTX renderer.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import logging
import posixpath
import re
import subprocess
import sys
import tomllib
from collections import Counter
from pathlib import Path
from typing import Any
from xml.etree import ElementTree as ET
from zipfile import ZIP_DEFLATED, BadZipFile, ZipFile

TEMPLATE_FILENAME = "ЛЦТ_2026_Шаблон презентации ФСП.pptx"
FROZEN_SLIDES = (7, 8, 9, 10, 11)
# Template slide used for every output slide. Slides 1-5 and 7-11 keep the template
# order. Template slide 6 only holds two raster logos and no text region, so the
# activity slide uses slide 20 of the template ("use templates 12-29" per slide 3):
# a heading bar, one large card and five row cards drawn by the template itself.
SLIDE_SOURCES = (1, 2, 3, 4, 5, 20, 7, 8, 9, 10, 11)
EXCLUDED_DIRECTORIES = {".git", "node_modules", "dist", "build", "coverage"}
NS = {
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "rel": "http://schemas.openxmlformats.org/package/2006/relationships",
}
LANGUAGES = {
    ".py": "Python",
    ".ts": "TypeScript",
    ".tsx": "TypeScript",
    ".js": "JavaScript",
    ".mjs": "JavaScript",
    ".cjs": "JavaScript",
    ".vue": "Vue",
    ".html": "HTML",
    ".css": "CSS",
    ".scss": "SCSS",
    ".sql": "SQL",
    ".go": "Go",
    ".rs": "Rust",
    ".java": "Java",
    ".c": "C",
    ".h": "C",
    ".cpp": "C++",
    ".cs": "C#",
    ".dart": "Dart",
}
FRAMEWORKS = {"vue", "nuxt", "@nuxt/ui", "fastapi", "django", "flask", "react", "angular"}
TOOLS = {
    "vite",
    "tailwindcss",
    "sass",
    "pinia",
    "vue-router",
    "typescript",
    "eslint",
    "vitest",
    "@playwright/test",
    "pytest",
    "ruff",
    "mypy",
    "sqlalchemy",
    "alembic",
    "pydantic",
    "uvicorn",
    "nats-py",
    "psycopg",
}
LOG = logging.getLogger(__name__)


class PresentationError(Exception):
    """An input or pipeline validation failure; no presentation can be produced."""


def git(repo: Path, *args: str, optional: bool = False) -> bytes:
    LOG.debug("git %s", " ".join(args))
    try:
        result = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, check=False)
    except OSError as exc:
        raise PresentationError(f"Cannot run Git: {exc}") from exc
    if result.returncode:
        if optional:
            return b""
        raise PresentationError(
            f"git {args[0]} failed: {result.stderr.decode('utf-8', errors='replace').strip()}"
        )
    LOG.debug("Git returned %d bytes", len(result.stdout))
    return result.stdout


def decode(value: bytes) -> str:
    return value.decode("utf-8", errors="surrogateescape")


def source_path(path: str) -> bool:
    return not EXCLUDED_DIRECTORIES.intersection(Path(path).parts[:-1])


def repository_name(root: Path) -> str:
    remote = decode(git(root, "remote", "get-url", "origin", optional=True)).strip()
    if remote:
        name = remote.rstrip("/").rsplit("/", 1)[-1].rsplit(":", 1)[-1]
        return name.removesuffix(".git")
    return root.name


def collect_repo_stats(repo: Path) -> dict[str, Any]:
    """Count index files, HEAD history and all-ref contributors using Git only."""
    root = Path(decode(git(repo, "rev-parse", "--show-toplevel")).strip()).resolve()
    if git(root, "rev-parse", "--is-shallow-repository").strip() == b"true":
        raise PresentationError(
            "Full Git history is required; run git fetch --unshallow before collecting facts."
        )
    head = decode(git(root, "rev-parse", "HEAD")).strip()
    entries = git(root, "ls-files", "--stage", "-z").split(b"\0")
    blobs: dict[str, str] = {}
    for entry in entries:
        if not entry:
            continue
        metadata, filename = entry.split(b"\t", 1)
        _mode, oid, stage = metadata.split()
        if stage != b"0":
            raise PresentationError("Resolve unmerged index entries before collecting facts.")
        path = decode(filename)
        if source_path(path):
            blobs[path] = decode(oid)
    paths = sorted(blobs)
    counts = Counter(Path(path).suffix.lower() or "[no extension]" for path in paths)
    manifests: list[dict[str, str]] = []
    dependencies: set[str] = set()
    for path in paths:
        if Path(path).name not in {"package.json", "pyproject.toml"}:
            continue
        content = git(root, "cat-file", "blob", blobs[path])
        manifests.append({"path": path, "git_blob": blobs[path]})
        try:
            if Path(path).name == "package.json":
                document = json.loads(content)
                if not isinstance(document, dict):
                    raise ValueError("expected a JSON object")
                for field in ("dependencies", "devDependencies", "peerDependencies"):
                    declared = document.get(field, {})
                    if not isinstance(declared, dict):
                        raise ValueError(f"{field} must be an object")
                    dependencies.update(declared)
            else:
                project = tomllib.loads(content.decode("utf-8")).get("project", {})
                requirements = project.get("dependencies", [])
                if not isinstance(requirements, list):
                    raise ValueError("project.dependencies must be an array")
                requirements = requirements.copy()
                for group in project.get("optional-dependencies", {}).values():
                    if not isinstance(group, list):
                        raise ValueError("optional dependency groups must be arrays")
                    requirements.extend(group)
                for requirement in requirements:
                    if not isinstance(requirement, str):
                        raise ValueError("dependency requirements must be strings")
                    match = re.match(r"[A-Za-z0-9][A-Za-z0-9_.-]*", requirement)
                    if match:
                        dependencies.add(match[0].lower().replace("_", "-"))
        except (ValueError, TypeError, AttributeError) as exc:
            raise PresentationError(f"Cannot read tracked manifest {path}: {exc}") from exc
    contributors = []
    for line in decode(git(root, "shortlog", "-sne", "--all")).splitlines():
        match = re.fullmatch(r"\s*(\d+)\s+(.+) <([^>]*)>", line)
        if not match:
            raise PresentationError(f"Cannot parse contributor record: {line!r}")
        contributors.append({"name": match[2], "email": match[3], "commits": int(match[1])})
    hot = Counter(
        decode(path)
        for path in git(root, "log", "--format=", "--name-only", "-z", "--no-renames").split(b"\0")
        if path and source_path(decode(path))
    )
    # A symbolic origin/HEAD points at a branch; it is not an additional branch.
    refs = decode(
        git(
            root,
            "for-each-ref",
            "--format=%(refname:short)\t%(symref)",
            "refs/heads",
            "refs/remotes",
        )
    ).splitlines()
    branches = sorted(line.split("\t", 1)[0] for line in refs if line.endswith("\t"))
    tools = dependencies.intersection(TOOLS)
    docker = any(
        Path(p).name.startswith("Dockerfile")
        or Path(p).name
        in {"docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"}
        for p in paths
    )
    ci = any(p.startswith(".github/workflows/") for p in paths)
    if docker:
        tools.add("Docker")
    if ci:
        tools.add("GitHub Actions")
    return {
        "repository": {"name": repository_name(root), "path": str(root)},
        "files": {
            "total": len(paths),
            "by_extension": [
                {"extension": extension, "count": count}
                for extension, count in sorted(counts.items(), key=lambda item: (-item[1], item[0]))
            ],
        },
        "git": {
            "commits": int(git(root, "rev-list", "--count", "HEAD")),
            "last_commit_date": decode(git(root, "log", "-1", "--format=%cI")).strip(),
            "branches": branches,
            "tags": decode(git(root, "tag", "--list")).splitlines(),
        },
        "contributors": contributors,
        "hot_files": [
            {"path": path, "mentions": count}
            for path, count in sorted(hot.items(), key=lambda item: (-item[1], item[0]))[:10]
        ],
        "technology": {
            "languages": sorted({LANGUAGES[ext] for ext in counts if ext in LANGUAGES}),
            "frameworks": sorted(dependencies.intersection(FRAMEWORKS)),
            "tools": sorted(tools),
        },
        "structure": {
            "directories": sorted(
                {str(parent) for p in paths for parent in Path(p).parents if str(parent) != "."}
            ),
            "has_readme": any(Path(p).name.lower().startswith("readme") for p in paths),
            "has_tests": any("tests" in Path(p).parts or "test" in Path(p).parts for p in paths),
            "has_ci": ci,
            "has_docker": docker,
            "has_frontend": any(p.startswith("front-end/") for p in paths),
            "has_backend": any(p.startswith("back-end/") for p in paths),
            "has_documentation": any(p.startswith("docs/") for p in paths),
        },
        "provenance": {
            "head": head,
            "index_tree": decode(git(root, "write-tree")).strip(),
            "file_scope": "Git index, excluding .git/node_modules/dist/build/coverage directories",
            "history_scope": "HEAD (contributors: all locally available refs, mailmap applied)",
            "branch_scope": "local and fetched remote refs, excluding symbolic refs",
            "hot_files_scope": (
                "HEAD history; name-only mentions, no rename detection; includes deletions"
            ),
            "technology_scope": (
                "tracked index manifests and recognized extensions/dependencies; "
                "declarations, not runtime verification"
            ),
            "manifests": manifests,
        },
    }


def xml(deck: ZipFile, part: str) -> ET.Element:
    try:
        return ET.fromstring(deck.read(part))
    except (KeyError, ET.ParseError) as exc:
        raise PresentationError(f"Missing or malformed PPTX XML part {part}: {exc}") from exc


def relationships(deck: ZipFile, part: str) -> list[dict[str, str]]:
    directory, name = posixpath.split(part)
    relpart = posixpath.join(directory, "_rels", name + ".rels")
    if relpart not in deck.namelist():
        return []
    result = []
    ids: set[str] = set()
    for rel in xml(deck, relpart):
        item = dict(rel.attrib)
        if not all(item.get(key) for key in ("Id", "Type", "Target")):
            raise PresentationError(f"PPTX relationship in {relpart} lacks required attributes.")
        if item["Id"] in ids:
            raise PresentationError(f"PPTX has duplicate relationship IDs in {relpart}.")
        ids.add(item["Id"])
        if item.get("TargetMode") != "External":
            target = item["Target"]
            target = posixpath.normpath(
                target.lstrip("/") if target.startswith("/") else posixpath.join(directory, target)
            )
            if target.startswith("../") or target not in deck.namelist():
                raise PresentationError(
                    f"PPTX relationship from {part} has invalid target {target}"
                )
            item["part"] = target
        result.append(item)
    return result


def shape_inventory(document: ET.Element) -> list[dict[str, Any]]:
    shapes = []
    kinds = {"sp", "pic", "graphicFrame", "grpSp", "cxnSp"}
    for element in document.iter():
        kind = element.tag.removeprefix(f"{{{NS['p']}}}")
        if kind not in kinds:
            continue
        properties = element.find(".//p:cNvPr", NS)
        placeholder = element.find(".//p:ph", NS) if kind != "grpSp" else None
        transform = element.find("./p:spPr/a:xfrm", NS)
        if transform is None:
            transform = element.find("./p:xfrm", NS)
        if transform is None:
            transform = element.find("./p:grpSpPr/a:xfrm", NS)
        geometry = (
            None
            if transform is None
            else {
                "attributes": dict(transform.attrib),
                **{child.tag.rsplit("}", 1)[-1]: dict(child.attrib) for child in transform},
            }
        )
        runs = []
        for run in element.findall("./p:txBody/a:p/a:r", NS):
            rpr = run.find("a:rPr", NS)
            runs.append(
                {
                    "text": run.findtext("a:t", default="", namespaces=NS),
                    "properties": None if rpr is None else dict(rpr.attrib),
                    "format_xml": None if rpr is None else ET.tostring(rpr, encoding="unicode"),
                }
            )
        text_body = element.find("p:txBody", NS)
        shape_xml = ET.tostring(element, encoding="unicode")
        shapes.append(
            {
                "kind": kind,
                "id": None if properties is None else properties.get("id"),
                "name": None if properties is None else properties.get("name"),
                "placeholder": None if placeholder is None else dict(placeholder.attrib),
                "geometry": geometry,
                "text": None
                if text_body is None
                else "\n".join(
                    "".join(
                        node.text or "" if node.tag == f"{{{NS['a']}}}t" else "\n"
                        for node in paragraph.iter()
                        if node.tag in {f"{{{NS['a']}}}t", f"{{{NS['a']}}}br"}
                    )
                    for paragraph in text_body.findall("a:p", NS)
                ),
                "runs": runs,
                "xml": shape_xml,
            }
        )
    return shapes


def inspect_template(templates_dir: Path) -> dict[str, Any]:
    """Inventory OOXML including raw styles; authorize no regions implicitly."""
    path = templates_dir / TEMPLATE_FILENAME
    if not path.is_file():
        raise PresentationError(
            f"Required FSP template not found: {path}. "
            "Issue #8 section 5 forbids generating a replacement."
        )
    if path.stat().st_size > 100 * 1024 * 1024:
        raise PresentationError("PPTX exceeds the 100 MiB inspection limit.")
    try:
        with ZipFile(path) as deck:
            infos = deck.infolist()
            if len(infos) > 10000 or sum(p.file_size for p in infos) > 200 * 1024 * 1024:
                raise PresentationError("PPTX exceeds the expanded-package inspection limit.")
            names = deck.namelist()
            if len(names) != len(set(names)):
                raise PresentationError("PPTX contains duplicate package parts.")
            document = xml(deck, "ppt/presentation.xml")
            slide_ids = document.findall("p:sldIdLst/p:sldId", NS)
            if len(slide_ids) < max(SLIDE_SOURCES):
                raise PresentationError(
                    f"FSP template must contain at least {max(SLIDE_SOURCES)} slides "
                    f"(the 11 output slides are taken from {list(SLIDE_SOURCES)}), "
                    f"found {len(slide_ids)}."
                )
            size = document.find("p:sldSz", NS)
            if size is None:
                raise PresentationError("PPTX has no slide dimensions.")
            try:
                dimensions = {key: int(size.attrib[key]) for key in ("cx", "cy")}
            except (KeyError, ValueError) as exc:
                raise PresentationError("PPTX has invalid slide dimensions.") from exc
            if min(dimensions.values()) <= 0:
                raise PresentationError("PPTX has non-positive slide dimensions.")
            rels = relationships(deck, "ppt/presentation.xml")
            by_id = {rel["Id"]: rel for rel in rels}
            slides = []
            used_parts = set()
            for number, source in enumerate(SLIDE_SOURCES, 1):
                slide_id = slide_ids[source - 1]
                rel = by_id.get(slide_id.get(f"{{{NS['r']}}}id", ""))
                if rel is None or not rel.get("Type", "").endswith("/slide") or "part" not in rel:
                    raise PresentationError(f"Slide {number} has no internal slide relationship.")
                part = rel["part"]
                if part in used_parts:
                    raise PresentationError("PPTX references a slide more than once.")
                used_parts.add(part)
                slide = xml(deck, part)
                if slide.tag != f"{{{NS['p']}}}sld":
                    raise PresentationError(f"Slide {number} is not a presentation slide.")
                shapes = shape_inventory(slide)
                background = slide.find("p:cSld/p:bg", NS)
                slide_rels = relationships(deck, part)
                slides.append(
                    {
                        "number": number,
                        "template_slide": source,
                        "part": part,
                        "frozen": number in FROZEN_SLIDES,
                        "sha256": hashlib.sha256(deck.read(part)).hexdigest(),
                        "layout": next(
                            (
                                r.get("part")
                                for r in slide_rels
                                if r.get("Type", "").endswith("/slideLayout")
                            ),
                            None,
                        ),
                        "background_xml": None
                        if background is None
                        else ET.tostring(background, encoding="unicode"),
                        "shapes": shapes,
                        "editable_elements": [],
                        "protected_elements": [s["id"] for s in shapes],
                        "placeholder_candidates": [
                            s["id"] for s in shapes if s["placeholder"] is not None
                        ],
                        "relationships": slide_rels,
                    }
                )
            components = []
            for part in sorted(names):
                if part.startswith(
                    ("ppt/slideMasters/", "ppt/slideLayouts/", "ppt/theme/", "ppt/charts/")
                ) and part.endswith(".xml"):
                    component = xml(deck, part)
                    components.append(
                        {
                            "part": part,
                            "sha256": hashlib.sha256(deck.read(part)).hexdigest(),
                            "xml": ET.tostring(component, encoding="unicode"),
                            "relationships": relationships(deck, part),
                        }
                    )
            return {
                "template": str(path.resolve()),
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "slide_count": len(slide_ids),
                "output_slide_count": len(SLIDE_SOURCES),
                "slide_size": dimensions,
                "slides": slides,
                "components": components,
                "media": [
                    {
                        "part": name,
                        "bytes": deck.getinfo(name).file_size,
                        "sha256": hashlib.sha256(deck.read(name)).hexdigest(),
                    }
                    for name in sorted(names)
                    if name.startswith("ppt/media/")
                ],
                "parts": [
                    {
                        "part": p.filename,
                        "bytes": p.file_size,
                        "sha256": hashlib.sha256(deck.read(p)).hexdigest(),
                    }
                    for p in infos
                ],
                "warnings": [
                    "Inspection is read-only; structural and visual QA have not been performed.",
                    "Elements stay protected until editable regions have been reviewed.",
                    "Null geometry/font values inherit; inspect layout/master/theme component XML.",
                ],
            }
    except (BadZipFile, ET.ParseError, RuntimeError, NotImplementedError) as exc:
        raise PresentationError(f"Invalid or unreadable PPTX template {path}: {exc}") from exc


Line = str | dict[str, Any]

# Styles for the template's empty cards on slide 6, taken from template slide 4:
# key numbers like the pink "01".."06" (36 pt bold), captions like its labels.
REGION_STYLES = {
    "heading": {"size": 20, "bold": True, "color": "FFFFFF"},
    "number": {"size": 36, "bold": True, "color": "FF0053"},
    "caption": {"size": 16, "bold": False, "color": "000000"},
    "note": {"size": 12, "bold": False, "color": "520977"},
    "row": {"size": 14, "bold": False, "color": "000000"},
    "title": {"size": 28, "bold": True, "color": "FFFFFF"},
    "subtitle": {"size": 16, "bold": False, "color": "FFFFFF"},
    "date": {"size": 14, "bold": False, "color": "FFFFFF"},
    "chip": {"size": 14, "bold": True, "color": "FFFFFF"},
    "chip_light": {"size": 14, "bold": True, "color": "310F53"},
}
FONT = "Montserrat"


def noun(count: int, one: str, few: str, many: str) -> str:
    """Russian noun form agreeing with ``count``."""
    if 11 <= count % 100 <= 14:
        return many
    if count % 10 == 1:
        return one
    return few if 2 <= count % 10 <= 4 else many


def plural(count: int, one: str, few: str, many: str) -> str:
    return f"{count} {noun(count, one, few, many)}"


def readme_subtitle(repo: Path) -> str | None:
    """The tagline after the dash in the first README heading, if present."""
    try:
        content = git(repo, "show", "HEAD:README.md", optional=True).decode("utf-8")
    except UnicodeDecodeError:
        return None
    for line in content.splitlines():
        if line.startswith("# "):
            _, dash, tagline = line.partition(" — ")
            return tagline.strip().capitalize() if dash and tagline.strip() else None
    return None


def short_path(path: str, limit: int = 48) -> str:
    if len(path) <= limit:
        return path
    name = path.rsplit("/", 1)[-1]
    return f"{path[: max(limit - len(name) - 2, 0)]}…/{name}"


def extension_label(extension: str) -> str:
    return "без расш." if extension == "[no extension]" else extension


def build_slide_spec(
    stats: dict[str, Any], presentation_name: str | None, subtitle: str | None
) -> list[dict[str, Any]]:
    """Map every fact to a reviewed template region; slides 7-11 receive no edits.

    Text-box edits are keyed by the first line of the template text they replace;
    each new line takes the formatting of the template paragraph at the same index.
    """
    files = stats["files"]["total"]
    commits = stats["git"]["commits"]
    contributors = len(stats["contributors"])
    branches = len(stats["git"]["branches"])
    extensions = stats["files"]["by_extension"]
    top, rest = extensions[:6], extensions[6:]
    date = stats["git"]["last_commit_date"]
    day = f"{date[8:10]}.{date[5:7]}.{date[0:4]}" if date else None
    name = presentation_name or stats["repository"]["name"]
    title: list[Line] = [{"text": name, "style": "title"}]
    if subtitle:
        title.append({"text": subtitle, "style": "subtitle"})
    if day:
        title.append({"text": f"Последний коммит: {day}", "style": "date"})
    labels = [f"{extension_label(item['extension'])} · {item['count']}" for item in top]
    labels += ["—"] * (6 - len(labels))
    rest_files = sum(item["count"] for item in rest)
    composition: dict[str, list[Line]] = {
        "ОФОРМЛЕНИЕ": ["СОСТАВ КОДА"],
        "ШРИФТ:": ["ФАЙЛЫ:"],
        "Montserrat:": [
            f"{plural(files, 'файл', 'файла', 'файлов')} под контролем Git, "
            f"{plural(len(extensions), 'тип', 'типа', 'типов')} расширений"
        ],
        "ЦВЕТА:": ["ТИПЫ:"],
        "акцентные": [f"топ-{len(top)}"],
        "базовые": ["остальные: источник git ls-files"],
        # The HEX rows span several chips, so each label goes into its own chip region.
        "HEX #FF0053": [""],
        "HEX #520978": [labels[5]],
        "HEX #FFFFFF": [""],
        "region:6": [{"text": plural(len(rest), "тип", "типа", "типов"), "style": "chip_light"}],
        "region:7": [{"text": plural(rest_files, "файл", "файла", "файлов"), "style": "chip"}],
    }
    for index, label in enumerate(labels[:5], 1):
        style = "chip_light" if index == 2 else "chip"
        composition[f"region:{index}"] = [{"text": label, "style": style}]
    hot = stats["hot_files"][:5]
    rows: dict[str, list[Line]] = {
        f"region:{index}": [
            {"text": f"{short_path(item['path'])} — {item['mentions']}", "style": "row"}
        ]
        for index, item in enumerate(hot, 2)
    }
    activity: dict[str, list[Line]] = {
        "region:1": [{"text": "АКТИВНОСТЬ", "style": "heading"}],
        # Template slide 20 carries its own page number; this slide is the 6th.
        "20": ["6"],
        "region:7": [
            {"text": str(commits), "style": "number"},
            {
                "text": f"{noun(commits, 'коммит', 'коммита', 'коммитов')} в истории HEAD",
                "style": "caption",
            },
            {"text": str(branches), "style": "number"},
            {
                "text": f"{noun(branches, 'ветка', 'ветки', 'веток')}: локальные и удалённые",
                "style": "caption",
            },
            {"text": day or "—", "style": "number"},
            {"text": "дата последнего коммита", "style": "caption"},
            {"text": f"Справа: топ-{len(hot)} файлов по числу изменений", "style": "note"},
        ],
        **rows,
    }
    specs: list[dict[str, Any]] = [
        {
            "purpose": "Что это за проект?",
            "source_data": [
                "presentation_name/repository.name",
                "README.md",
                "git.last_commit_date",
            ],
            "edits": {"region:subtitle": title},
        },
        {
            "purpose": "Каков масштаб проекта?",
            "source_data": [
                "files.total",
                "git.commits",
                "contributors",
                "files.by_extension",
                "git.branches",
            ],
            "edits": {
                "ВВОДНЫЕ": ["ОБЗОР"],
                "Привет, участник": ["Проект в цифрах"],
                "Эта презентация": [
                    f"{plural(files, 'файл', 'файла', 'файлов')} под контролем Git",
                    f"{plural(commits, 'коммит', 'коммита', 'коммитов')} в истории HEAD",
                    f"{plural(contributors, 'участник', 'участника', 'участников')} по всем веткам",
                ],
                "Можешь смело": [
                    f"{plural(len(extensions), 'тип', 'типа', 'типов')} файлов по расширениям",
                    f"{plural(branches, 'ветка', 'ветки', 'веток')}, локальные и удалённые",
                ],
                "Удачи!": [""],
            },
        },
        {
            "purpose": "Что будет показано?",
            "source_data": ["slide specification"],
            "edits": {
                "Титульный слайд": ["Проект"],
                "название команды": ["название и дата"],
                "название задачи": ["цифры Git"],
                "логотип / логотипы": ["структура", "презентации"],
                "Используй для оформления\nслайд 7": ["Слайды 1–4"],
                "Слайды про задачу": ["Кодовая база"],
                "описание сути и": ["состав по", "расширениям"],
                "план по дальнейшему": ["число коммитов"],
                "ФИО и контактные": ["число веток"],
                "роли в команде": ["дата коммита"],
                "сложности и вызовы": ["самые изменяемые", "файлы"],
                "Используй для оформления\nслайды 8-11": ["Слайды 5–6"],
                "Обязательный блок#1": ["Источник: Git"],
                "Обязательный блок#2": ["Источник: Git"],
                "Презентация": ["Шаблон ФСП"],
                "рекомендуемая": ["о команде", "и решении"],
                "этот блок должен быть": ["слайды шаблона", "без изменений"],
                "Используй для оформления\nшаблоны": ["Слайды 7–11"],
            },
        },
        {
            "purpose": "Как структурирована презентация?",
            "source_data": ["template slide 4 (six blocks kept verbatim)"],
            "edits": {},
        },
        {
            "purpose": "Из чего состоит кодовая база?",
            "source_data": ["files.by_extension"],
            "edits": composition,
        },
        {
            "purpose": "Насколько активно развивается проект?",
            "source_data": ["git.commits", "git.branches", "git.last_commit_date", "hot_files"],
            "edits": activity,
        },
    ]
    for _ in FROZEN_SLIDES:
        specs.append(
            {"purpose": "Что предусмотрено шаблоном ФСП.", "source_data": ["template"], "edits": {}}
        )
    for number, (spec, source) in enumerate(zip(specs, SLIDE_SOURCES, strict=True), 1):
        spec["slide_number"] = number
        spec["template_slide"] = source
        spec["frozen"] = number in FROZEN_SLIDES
    return specs


def register_namespaces() -> None:
    for prefix, uri in NS.items():
        if prefix != "rel":
            ET.register_namespace(prefix, uri)


def package_xml(root: ET.Element) -> bytes:
    """Serialise a single-namespace package part with that namespace as the default."""
    data: bytes = ET.tostring(root, xml_declaration=True, encoding="UTF-8")
    return data.replace(b"xmlns:ns0=", b"xmlns=").replace(b"<ns0:", b"<").replace(b"</ns0:", b"</")


def shape_text(shape: ET.Element) -> str:
    """Paragraph texts without the trailing spaces the PDF export left behind."""
    return "\n".join(
        "".join(t.text or "" for t in paragraph.iter(f"{{{NS['a']}}}t")).strip()
        for paragraph in shape.findall("p:txBody/a:p", NS)
    )


def shape_name(shape: ET.Element) -> str | None:
    properties = shape.find("p:nvSpPr/p:cNvPr", NS)
    return None if properties is None else properties.get("name")


def styled_run(paragraph: ET.Element, text: str, style: dict[str, Any]) -> None:
    run = ET.SubElement(paragraph, f"{{{NS['a']}}}r")
    rpr = ET.SubElement(
        run,
        f"{{{NS['a']}}}rPr",
        {"lang": "ru-RU", "sz": str(style["size"] * 100), "b": "1" if style["bold"] else "0"},
    )
    fill = ET.SubElement(rpr, f"{{{NS['a']}}}solidFill")
    ET.SubElement(fill, f"{{{NS['a']}}}srgbClr", {"val": style["color"]})
    ET.SubElement(rpr, f"{{{NS['a']}}}latin", {"typeface": FONT})
    ET.SubElement(run, f"{{{NS['a']}}}t").text = text


def replace_text(shape: ET.Element, lines: list[Line]) -> None:
    """Swap paragraphs; formatting comes from the template paragraph at each index."""
    body = shape.find("p:txBody", NS)
    if body is None:
        raise PresentationError("Edited shape has no text body.")
    template = body.findall("a:p", NS)
    for paragraph in template:
        body.remove(paragraph)
    for index, line in enumerate(lines):
        model = template[min(index, len(template) - 1)] if template else None
        paragraph = ET.SubElement(body, f"{{{NS['a']}}}p")
        if isinstance(line, dict):
            ET.SubElement(paragraph, f"{{{NS['a']}}}pPr").append(ET.Element(f"{{{NS['a']}}}buNone"))
            styled_run(paragraph, line["text"], REGION_STYLES[line["style"]])
            continue
        properties = None if model is None else model.find("a:pPr", NS)
        if properties is not None:
            paragraph.append(copy.deepcopy(properties))
        runs = [] if model is None else model.findall("a:r", NS)
        if not runs:
            raise PresentationError("A plain-text edit needs a formatted template paragraph.")
        run = copy.deepcopy(runs[0])
        run_text = run.find("a:t", NS)
        assert run_text is not None
        run_text.text = line
        paragraph.append(run)


def apply_edits(slide: ET.Element, edits: dict[str, list[Line]], number: int) -> None:
    shapes = [s for s in slide.iter(f"{{{NS['p']}}}sp") if s.find("p:txBody", NS) is not None]
    for key, lines in edits.items():
        # "text#n" selects the n-th region (in document order) starting with that text.
        prefix, separator, ordinal = key.rpartition("#")
        if not (separator and ordinal.isdigit() and len(ordinal) <= 2):
            prefix, ordinal = key, ""
        if key.startswith("region:"):
            matches = [s for s in shapes if shape_name(s) == key]
        else:
            matches = [s for s in shapes if shape_text(s).startswith(prefix)]
            if ordinal and len(matches) >= int(ordinal):
                matches = [matches[int(ordinal) - 1]]
        if len(matches) != 1:
            raise PresentationError(
                f"Slide {number}: expected one template region for {key!r}, found {len(matches)}."
            )
        replace_text(matches[0], lines)


def assemble(template: Path, specs: list[dict[str, Any]], output: Path) -> None:
    """Copy the template package, keep the selected slides in order and edit text only."""
    register_namespaces()
    with ZipFile(template) as deck:
        document = xml(deck, "ppt/presentation.xml")
        id_list = document.find("p:sldIdLst", NS)
        assert id_list is not None
        slide_ids = list(id_list)
        by_id = {rel["Id"]: rel for rel in relationships(deck, "ppt/presentation.xml")}
        keep = [slide_ids[spec["template_slide"] - 1] for spec in specs]
        drop = [element for element in slide_ids if element not in keep]
        for element in slide_ids:
            id_list.remove(element)
        id_list.extend(keep)
        dropped_rels = {element.get(f"{{{NS['r']}}}id") for element in drop}
        kept_parts = {by_id[e.get(f"{{{NS['r']}}}id", "")]["part"] for e in keep}
        dropped_parts = {by_id[r]["part"] for r in dropped_rels if r}
        used = set(kept_parts)
        for part in kept_parts:
            used.update(rel["part"] for rel in relationships(deck, part) if "part" in rel)
        removed = set()
        for part in dropped_parts:
            directory, name = posixpath.split(part)
            removed.add(part)
            removed.add(posixpath.join(directory, "_rels", name + ".rels"))
            removed.update(
                rel["part"]
                for rel in relationships(deck, part)
                if "part" in rel
                and rel["part"] not in used
                and rel["part"].startswith("ppt/media/")
            )
        edited = {}
        for spec in specs:
            part = by_id[keep[spec["slide_number"] - 1].get(f"{{{NS['r']}}}id", "")]["part"]
            if spec["edits"]:
                slide = xml(deck, part)
                apply_edits(slide, spec["edits"], spec["slide_number"])
                edited[part] = ET.tostring(slide, xml_declaration=True, encoding="UTF-8")
        rels = ET.fromstring(deck.read("ppt/_rels/presentation.xml.rels"))
        for rel in list(rels):
            if rel.get("Id") in dropped_rels:
                rels.remove(rel)
        types = ET.fromstring(deck.read("[Content_Types].xml"))
        for override in list(types):
            if override.get("PartName", "").lstrip("/") in removed:
                types.remove(override)
        replaced = {
            "ppt/presentation.xml": ET.tostring(document, xml_declaration=True, encoding="UTF-8"),
            # Package parts must use a default namespace: LibreOffice rejects "ns0:" prefixes.
            "ppt/_rels/presentation.xml.rels": package_xml(rels),
            "[Content_Types].xml": package_xml(types),
            **edited,
        }
        output.parent.mkdir(parents=True, exist_ok=True)
        with ZipFile(output, "w", ZIP_DEFLATED) as result:
            for info in deck.infolist():
                if info.filename in removed:
                    continue
                result.writestr(info, replaced.get(info.filename, deck.read(info)))


def geometry(slide: ET.Element) -> list[tuple[str | None, str]]:
    return [(s["name"], json.dumps(s["geometry"], sort_keys=True)) for s in shape_inventory(slide)]


def structural_qa(
    template: Path, output: Path, specs: list[dict[str, Any]], inspection: dict[str, Any]
) -> list[str]:
    """Return failed checks of section 18; an empty list means PASS."""
    errors: list[str] = []
    try:
        deck = ZipFile(output)
    except (OSError, BadZipFile) as exc:
        return [f"output does not open: {exc}"]
    with deck, ZipFile(template) as source:
        if deck.testzip() is not None:
            errors.append("output package has a corrupt member")
        document = xml(deck, "ppt/presentation.xml")
        size = document.find("p:sldSz", NS)
        if (
            size is None
            or {k: int(size.get(k, 0)) for k in ("cx", "cy")} != inspection["slide_size"]
        ):
            errors.append("slide size differs from the template")
        slide_ids = document.findall("p:sldIdLst/p:sldId", NS)
        if len(slide_ids) != len(SLIDE_SOURCES):
            errors.append(f"expected {len(SLIDE_SOURCES)} slides, found {len(slide_ids)}")
        by_id = {rel["Id"]: rel for rel in relationships(deck, "ppt/presentation.xml")}
        for spec, slide_id, expected in zip(specs, slide_ids, inspection["slides"], strict=False):
            number = spec["slide_number"]
            part = by_id[slide_id.get(f"{{{NS['r']}}}id", "")]["part"]
            if part != expected["part"]:
                errors.append(f"slide {number} is not template slide {spec['template_slide']}")
                continue
            if spec["frozen"] and deck.read(part) != source.read(part):
                errors.append(f"frozen slide {number} was modified")
            slide, original = xml(deck, part), xml(source, part)
            if geometry(slide) != geometry(original):
                errors.append(f"slide {number}: objects were added, removed or moved")
            for rel in relationships(deck, part):
                if "part" in rel and deck.read(rel["part"]) != source.read(rel["part"]):
                    errors.append(f"slide {number}: media {rel['part']} differs")
            texts = [s["text"] for s in shape_inventory(slide) if s["text"] is not None]
            for key, lines in spec["edits"].items():
                wanted = "\n".join(
                    line if isinstance(line, str) else line["text"] for line in lines
                )
                # An all-empty edit clears template sample text on purpose.
                if wanted not in texts:
                    errors.append(f"slide {number}: region {key!r} is not filled")
    return errors


def write_json(path: Path, content: dict[str, Any]) -> None:
    path.write_text(json.dumps(content, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-path", type=Path, required=True)
    parser.add_argument("--templates-dir", type=Path, required=True)
    parser.add_argument("--report-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, help="PPTX path; omit to stop after inspection")
    parser.add_argument("--presentation-name")
    parser.add_argument("--soffice", help="LibreOffice binary for visual QA")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args(argv)
    if args.verbose:
        logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")
    completed: list[str] = []
    warnings: list[str] = []
    status: dict[str, Any] = {
        "status": "BLOCKED",
        "completed_stages": completed,
        "output": None,
        "frozen_slides": list(FROZEN_SLIDES),
        "structural_qa": "NOT_RUN",
        "visual_qa": "NOT_RUN",
        "warnings": warnings,
    }
    try:
        # Use a fresh directory so old success reports cannot survive a failed run.
        args.report_dir.mkdir(parents=True, exist_ok=False)
        stats = collect_repo_stats(args.repo_path)
        write_json(args.report_dir / "repo_stats.json", stats)
        completed.append("data_extraction")
        template = inspect_template(args.templates_dir)
        write_json(args.report_dir / "template_inspection.json", template)
        completed.append("template_inspection")
        if args.output is None:
            status["status"] = "PREFLIGHT_COMPLETE"
            warnings.append("No --output given: slide specification and assembly were skipped.")
            write_json(args.report_dir / "status.json", status)
            print(f"PREFLIGHT COMPLETE: {args.report_dir}; no presentation generated.")
            return 0
        specs = build_slide_spec(
            stats, args.presentation_name, readme_subtitle(Path(stats["repository"]["path"]))
        )
        write_json(args.report_dir / "slide_spec.json", {"slides": specs})
        completed.append("slide_specification")
        template_path = Path(template["template"])
        assemble(template_path, specs, args.output)
        status["output"] = str(args.output)
        completed.append("assembly")
        errors = structural_qa(template_path, args.output, specs, template)
        status["structural_qa"] = "FAIL" if errors else "PASS"
        status["structural_errors"] = errors
        completed.append("structural_qa")
        soffice = None
        try:
            from tools.fsp_visual_qa import find_soffice, visual_qa
        except ImportError as exc:
            warnings.append(f"Visual QA needs pymupdf and Pillow: {exc}")
        else:
            soffice = find_soffice(args.soffice)
            if soffice is None:
                warnings.append("Visual QA skipped: LibreOffice (soffice) was not found.")
            else:
                visual = visual_qa(
                    soffice,
                    template_path,
                    args.output,
                    args.report_dir,
                    {s["slide_number"] for s in specs if s["edits"]},
                )
                status["visual_qa"] = "FAIL" if visual else "PASS"
                status["visual_errors"] = visual
                completed.append("visual_qa")
        warnings.append(
            "Frozen slides 7-11 keep the template text: team members, contacts and the "
            "solution description are not recorded in Git."
        )
        passed = status["structural_qa"] == "PASS" and status["visual_qa"] != "FAIL"
        status["status"] = "GENERATED" if passed else "QA_FAILED"
        write_json(args.report_dir / "status.json", status)
        print(
            "\n".join(
                [
                    "PRESENTATION GENERATED" if passed else "PRESENTATION QA FAILED",
                    f"Output: {args.output}",
                    f"Slides: {len(specs)}",
                    f"Repository: {stats['repository']['name']}",
                    f"Files: {stats['files']['total']}",
                    f"Commits: {stats['git']['commits']}",
                    f"Contributors: {len(stats['contributors'])}",
                    "Frozen slides: " + ", ".join(map(str, FROZEN_SLIDES)),
                    f"Structural QA: {status['structural_qa']}",
                    f"Visual QA: {status['visual_qa']}",
                    "Warnings:",
                    *(f"- {item}" for item in warnings + errors + status.get("visual_errors", [])),
                ]
            )
        )
        return 0 if passed else 1
    except (PresentationError, OSError) as exc:
        status["error"] = str(exc)
        if args.report_dir.is_dir() and not isinstance(exc, FileExistsError):
            try:
                write_json(args.report_dir / "status.json", status)
            except OSError as report_error:
                print(f"Cannot save failure report: {report_error}", file=sys.stderr)
        print(f"PRESENTATION BLOCKED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
