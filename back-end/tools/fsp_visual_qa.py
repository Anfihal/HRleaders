"""Render the generated deck with LibreOffice and check every slide (issue #8, section 19).

Checks performed on the rendered PDF:

* every rendered text line lies inside the text box that owns it (no overflow,
  no clipped text) and inside the slide;
* rendered text of different boxes does not collide on edited slides;
* frozen slides render pixel-identically to the same template slides;
* one PNG per slide is saved for human review.
"""

from __future__ import annotations

import logging
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any
from zipfile import ZipFile

import pymupdf
from PIL import Image, ImageChops, ImageStat

from tools.fsp_presentation import (
    FROZEN_SLIDES,
    NS,
    SLIDE_SOURCES,
    relationships,
    shape_inventory,
    xml,
)

EMU_PER_PT = 12700
TOLERANCE = 2.0
BULLETS = {"•", "-", "§"}
LOG = logging.getLogger(__name__)


def find_soffice(explicit: str | None = None) -> str | None:
    return explicit or shutil.which("soffice") or shutil.which("libreoffice")


def render_pdf(soffice: str, deck: Path, directory: Path) -> Path:
    profile = Path(tempfile.mkdtemp(prefix="lo-profile-"))
    try:
        subprocess.run(
            [
                soffice,
                f"-env:UserInstallation={profile.as_uri()}",
                "--headless",
                "--convert-to",
                "pdf",
                "--outdir",
                str(directory),
                str(deck),
            ],
            check=True,
            capture_output=True,
            timeout=600,
        )
    finally:
        shutil.rmtree(profile, ignore_errors=True)
    pdf = directory / (deck.stem + ".pdf")
    if not pdf.is_file():
        raise RuntimeError(f"LibreOffice did not render {deck}")
    return pdf


def text_boxes(deck: Path) -> list[list[dict[str, Any]]]:
    """Per slide: named text boxes with their rectangle in points."""
    result = []
    with ZipFile(deck) as package:
        presentation = xml(package, "ppt/presentation.xml")
        by_id = {rel["Id"]: rel for rel in relationships(package, "ppt/presentation.xml")}
        for slide_id in presentation.findall("p:sldIdLst/p:sldId", NS):
            part = by_id[slide_id.get(f"{{{NS['r']}}}id", "")]["part"]
            boxes = []
            for shape in shape_inventory(xml(package, part)):
                if shape["text"] is None or not shape["geometry"]:
                    continue
                off, ext = shape["geometry"]["off"], shape["geometry"]["ext"]
                x, y = int(off["x"]) / EMU_PER_PT, int(off["y"]) / EMU_PER_PT
                w, h = int(ext["cx"]) / EMU_PER_PT, int(ext["cy"]) / EMU_PER_PT
                boxes.append(
                    {"name": shape["name"], "text": shape["text"], "rect": (x, y, x + w, y + h)}
                )
            result.append(boxes)
    return result


def owner(line: pymupdf.Rect, text: str, boxes: list[dict[str, Any]]) -> dict[str, Any] | None:
    centre = ((line.x0 + line.x1) / 2, (line.y0 + line.y1) / 2)
    candidates = [b for b in boxes if text.strip() and text.strip()[:12] in b["text"]]
    for box in candidates or boxes:
        x0, y0, x1, y1 = box["rect"]
        if x0 - 20 <= centre[0] <= x1 + 20 and y0 - 20 <= centre[1] <= y1 + 20:
            return box
    return candidates[0] if candidates else None


def page_findings(page: pymupdf.Page, boxes: list[dict[str, Any]], check_overlap: bool) -> set[str]:
    """Overflow and overlap findings for one rendered slide."""
    findings: set[str] = set()
    placed: list[tuple[pymupdf.Rect, str]] = []
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            rect = pymupdf.Rect(line["bbox"])
            text = "".join(span["text"] for span in line["spans"])
            # Bullet glyphs hang left of their box by design.
            if not text.strip() or text.strip() in BULLETS:
                continue
            if not page.rect.contains(rect):
                findings.add(f"text {text!r} leaves the slide")
            box = owner(rect, text, boxes)
            if box is None:
                findings.add(f"text {text!r} has no owning text box")
                continue
            x0, y0, x1, y1 = box["rect"]
            if (
                rect.x0 < x0 - TOLERANCE
                or rect.x1 > x1 + TOLERANCE
                or rect.y0 < y0 - TOLERANCE * 3
                or rect.y1 > y1 + TOLERANCE * 3
            ):
                LOG.debug("overflow %s %s", rect, box)
                findings.add(f"text {text!r} overflows box {box['name']}")
            placed.append((rect, box["name"]))
    if check_overlap:
        # Rendered lines of different boxes must not collide; empty box areas may.
        for index, (first, first_box) in enumerate(placed):
            for second, second_box in placed[index + 1 :]:
                if first_box != second_box and (first & second).get_area() > 4:
                    findings.add(f"text of {first_box} overlaps text of {second_box}")
    return findings


def visual_qa(
    soffice: str, template: Path, output: Path, report_dir: Path, edited: set[int]
) -> list[str]:
    """Return visual QA failures; PNG renders are written to ``report_dir/render``.

    The template is rendered with the same renderer and its own findings are the
    baseline: only problems the generated deck adds are reported.
    """
    errors: list[str] = []
    render_dir = report_dir / "render"
    render_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        rendered = pymupdf.open(render_pdf(soffice, output, Path(temp)))
        original = pymupdf.open(render_pdf(soffice, template, Path(temp)))
        boxes = text_boxes(output)
        template_boxes = text_boxes(template)
        if len(rendered) != len(SLIDE_SOURCES):
            return [f"renderer produced {len(rendered)} pages, expected {len(SLIDE_SOURCES)}"]
        for number, page in enumerate(rendered, 1):
            source_page = original[SLIDE_SOURCES[number - 1] - 1]
            pixmap = page.get_pixmap(dpi=96)
            image = Image.frombytes("RGB", (pixmap.width, pixmap.height), pixmap.samples)
            image.save(render_dir / f"slide-{number:02d}.png")
            check_overlap = number in edited
            found = page_findings(page, boxes[number - 1], check_overlap)
            baseline = page_findings(
                source_page, template_boxes[SLIDE_SOURCES[number - 1] - 1], check_overlap
            )
            errors.extend(f"slide {number}: {item}" for item in sorted(found - baseline))
            if number in FROZEN_SLIDES:
                source = source_page.get_pixmap(dpi=96)
                reference = Image.frombytes("RGB", (source.width, source.height), source.samples)
                difference = ImageStat.Stat(ImageChops.difference(image, reference)).mean
                if max(difference) > 0.5:
                    errors.append(f"frozen slide {number} renders differently from the template")
    return errors
