from __future__ import annotations

import html
import re
import shutil
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import landscape, letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    CondPageBreak,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
TMP_DIR = ROOT / "tmp" / "pdfs"
OUT_DIR = ROOT / "output" / "pdf"
TMP_PDF = TMP_DIR / "secure-vim-setup-printable.pdf"
OUT_PDF = OUT_DIR / "secure-vim-setup-printable.pdf"

CODE_FILES = [
    ("~/.vimrc", ROOT / "vimrc"),
    ("~/.vim/config/options.vim", ROOT / "config" / "options.vim"),
    ("~/.vim/config/theme.vim", ROOT / "config" / "theme.vim"),
    ("~/.vim/config/mappings.vim", ROOT / "config" / "mappings.vim"),
    ("~/.vim/config/completion.vim", ROOT / "config" / "completion.vim"),
    ("~/.vim/config/pairs.vim", ROOT / "config" / "pairs.vim"),
]

NAVY = colors.HexColor("#1f2a44")
BLUE = colors.HexColor("#3d66a5")
PALE_BLUE = colors.HexColor("#e9eef8")
INK = colors.HexColor("#172033")
MUTED = colors.HexColor("#687386")
RULE = colors.HexColor("#c9d1df")
CODE_BG = colors.HexColor("#f7f8fb")
WHITE = colors.white


def ascii_safe(text: str) -> str:
    replacements = {
        "\u2013": "-",
        "\u2014": "-",
        "\u2018": "'",
        "\u2019": "'",
        "\u201c": '"',
        "\u201d": '"',
        "\u2026": "...",
        "\u00a0": " ",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text


def inline_markup(text: str) -> str:
    text = ascii_safe(text.strip())
    pieces: list[str] = []
    pos = 0
    token_re = re.compile(r"`([^`]+)`|\[([^\]]+)\]\([^\)]+\)")
    for match in token_re.finditer(text):
        pieces.append(html.escape(text[pos : match.start()]))
        if match.group(1) is not None:
            pieces.append(f'<font name="Courier">{html.escape(match.group(1))}</font>')
        else:
            pieces.append(html.escape(match.group(2)))
        pos = match.end()
    pieces.append(html.escape(text[pos:]))
    return "".join(pieces)


def add_markdown(story: list, markdown: str, styles: dict[str, ParagraphStyle]) -> None:
    lines = markdown.splitlines()
    i = 0
    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip()
        if not stripped:
            story.append(Spacer(1, 3))
            i += 1
            continue

        heading = re.match(r"^(#{1,3})\s+(.+)$", stripped)
        if heading:
            level = len(heading.group(1))
            story.append(Paragraph(inline_markup(heading.group(2)), styles[f"h{level}"]))
            i += 1
            continue

        if stripped.startswith("|"):
            table_lines: list[str] = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i].strip())
                i += 1
            rows = [
                [cell.strip() for cell in line.strip("|").split("|")]
                for line in table_lines
            ]
            if len(rows) >= 2 and all(re.fullmatch(r":?-{3,}:?", c) for c in rows[1]):
                rows.pop(1)
            data = [
                [Paragraph(inline_markup(cell), styles["table_head" if r == 0 else "table_body"])
                 for cell in row]
                for r, row in enumerate(rows)
            ]
            table = Table(data, colWidths=[2.05 * inch, 4.75 * inch, 2.95 * inch], repeatRows=1)
            table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), NAVY),
                ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("GRID", (0, 0), (-1, -1), 0.4, RULE),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [WHITE, CODE_BG]),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]))
            story.extend([table, Spacer(1, 8)])
            continue

        list_match = re.match(r"^(\d+\.|-)\s+(.+)$", stripped)
        if list_match:
            marker = list_match.group(1)
            text_parts = [list_match.group(2)]
            i += 1
            while i < len(lines) and lines[i].startswith("   ") and lines[i].strip():
                text_parts.append(lines[i].strip())
                i += 1
            bullet = marker if marker != "-" else "-"
            story.append(Paragraph(inline_markup(" ".join(text_parts)), styles["list"], bulletText=bullet))
            continue

        paragraph = [stripped]
        i += 1
        while i < len(lines):
            candidate = lines[i]
            candidate_stripped = candidate.strip()
            if not candidate_stripped:
                break
            if re.match(r"^(#{1,3})\s+", candidate_stripped):
                break
            if candidate_stripped.startswith("|"):
                break
            if re.match(r"^(\d+\.|-)\s+", candidate_stripped):
                break
            paragraph.append(candidate_stripped)
            i += 1
        story.append(Paragraph(inline_markup(" ".join(paragraph)), styles["body"]))


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "Title", parent=base["Title"], fontName="Helvetica-Bold", fontSize=25,
            leading=29, textColor=NAVY, alignment=TA_LEFT, spaceAfter=10,
        ),
        "subtitle": ParagraphStyle(
            "Subtitle", parent=base["Normal"], fontName="Helvetica", fontSize=11.5,
            leading=16, textColor=MUTED, spaceAfter=16,
        ),
        "h1": ParagraphStyle(
            "H1", parent=base["Heading1"], fontName="Helvetica-Bold", fontSize=18,
            leading=22, textColor=NAVY, spaceBefore=12, spaceAfter=7,
        ),
        "h2": ParagraphStyle(
            "H2", parent=base["Heading2"], fontName="Helvetica-Bold", fontSize=13,
            leading=16, textColor=BLUE, spaceBefore=11, spaceAfter=5, keepWithNext=True,
        ),
        "h3": ParagraphStyle(
            "H3", parent=base["Heading3"], fontName="Helvetica-Bold", fontSize=10.5,
            leading=13, textColor=INK, spaceBefore=8, spaceAfter=4, keepWithNext=True,
        ),
        "body": ParagraphStyle(
            "Body", parent=base["BodyText"], fontName="Helvetica", fontSize=9,
            leading=12.2, textColor=INK, spaceAfter=5,
        ),
        "list": ParagraphStyle(
            "List", parent=base["BodyText"], fontName="Helvetica", fontSize=8.7,
            leading=11.6, leftIndent=20, firstLineIndent=-15, bulletIndent=2,
            textColor=INK, spaceAfter=3,
        ),
        "table_head": ParagraphStyle(
            "TableHead", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=7.5,
            leading=9.3, textColor=WHITE,
        ),
        "table_body": ParagraphStyle(
            "TableBody", parent=base["Normal"], fontName="Helvetica", fontSize=7.2,
            leading=9.2, textColor=INK,
        ),
        "callout": ParagraphStyle(
            "Callout", parent=base["BodyText"], fontName="Helvetica-Bold", fontSize=9.5,
            leading=13, textColor=NAVY,
        ),
        "file_title": ParagraphStyle(
            "FileTitle", parent=base["Heading1"], fontName="Helvetica-Bold", fontSize=16,
            leading=19, textColor=NAVY, spaceAfter=2,
        ),
        "file_meta": ParagraphStyle(
            "FileMeta", parent=base["Normal"], fontName="Helvetica", fontSize=8.5,
            leading=11, textColor=MUTED, spaceAfter=8,
        ),
        "code": ParagraphStyle(
            "Code", parent=base["Code"], fontName="Courier", fontSize=6.25,
            leading=7.45, textColor=INK, leftIndent=0, rightIndent=0,
        ),
        "code_header": ParagraphStyle(
            "CodeHeader", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=7,
            leading=8.5, textColor=WHITE,
        ),
        "line_no": ParagraphStyle(
            "LineNo", parent=base["Code"], fontName="Courier", fontSize=6.1,
            leading=7.45, textColor=MUTED, alignment=TA_LEFT,
        ),
        "cheat_title": ParagraphStyle(
            "CheatTitle", parent=base["Title"], fontName="Helvetica-Bold", fontSize=21,
            leading=24, textColor=NAVY, spaceAfter=12,
        ),
        "cheat_section": ParagraphStyle(
            "CheatSection", parent=base["Heading3"], fontName="Helvetica-Bold", fontSize=9,
            leading=10.5, textColor=WHITE,
        ),
        "cheat_key": ParagraphStyle(
            "CheatKey", parent=base["Code"], fontName="Courier-Bold", fontSize=6.7,
            leading=8, textColor=NAVY, leftIndent=0, rightIndent=0, firstLineIndent=0,
        ),
        "cheat_desc": ParagraphStyle(
            "CheatDesc", parent=base["Normal"], fontName="Helvetica", fontSize=6.7,
            leading=8, textColor=INK,
        ),
    }


def page_chrome(canvas, doc) -> None:
    width, height = landscape(letter)
    canvas.saveState()
    canvas.setStrokeColor(RULE)
    canvas.setLineWidth(0.5)
    canvas.line(doc.leftMargin, height - 24, width - doc.rightMargin, height - 24)
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(doc.leftMargin, height - 18, "CLOSED-INTRANET VIM SETUP - PRINTABLE RETYPING GUIDE")
    canvas.drawRightString(width - doc.rightMargin, 16, f"Page {doc.page}")
    canvas.drawString(doc.leftMargin, 16, "Generated from the repository source; code lines are numbered for checking only.")
    canvas.restoreState()


def code_table(display_name: str, source: Path, styles: dict[str, ParagraphStyle]) -> Table:
    lines = source.read_text(encoding="utf-8").splitlines()
    data = [["LINE", display_name]]
    for number, line in enumerate(lines, 1):
        data.append([str(number), ascii_safe(line) if line else " "])
    table = Table(data, colWidths=[0.43 * inch, 9.32 * inch], repeatRows=1, hAlign="LEFT")
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("BACKGROUND", (0, 1), (0, -1), PALE_BLUE),
        ("BACKGROUND", (1, 1), (1, -1), CODE_BG),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, 0), 7),
        ("LEADING", (0, 0), (-1, 0), 8.2),
        ("FONTNAME", (0, 1), (-1, -1), "Courier"),
        ("FONTSIZE", (0, 1), (0, -1), 6.7),
        ("FONTSIZE", (1, 1), (1, -1), 7),
        ("LEADING", (0, 1), (-1, -1), 8.2),
        ("TEXTCOLOR", (0, 1), (0, -1), MUTED),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LINEBELOW", (0, 0), (-1, 0), 0.7, NAVY),
        ("LINEAFTER", (0, 0), (0, -1), 0.35, RULE),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 0.8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 0.8),
    ]))
    return table


def cheat_category(title: str, entries: list[tuple[str, str]], styles: dict[str, ParagraphStyle]) -> list:
    heading = Table(
        [[Paragraph(title, styles["cheat_section"])]],
        colWidths=[3.02 * inch],
        style=TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), NAVY),
            ("LEFTPADDING", (0, 0), (-1, -1), 5),
            ("RIGHTPADDING", (0, 0), (-1, -1), 5),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ]),
    )
    rows = [
        [Paragraph(html.escape(key), styles["cheat_key"]), Paragraph(html.escape(desc), styles["cheat_desc"])]
        for key, desc in entries
    ]
    body = Table(rows, colWidths=[1.16 * inch, 1.86 * inch])
    body.setStyle(TableStyle([
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [WHITE, CODE_BG]),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LINEBELOW", (0, 0), (-1, -1), 0.25, RULE),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 1.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 1.5),
    ]))
    return [heading, body, Spacer(1, 7)]


def add_cheat_sheet(story: list, styles: dict[str, ParagraphStyle]) -> None:
    columns = [
        [
            ("Everyday", [
                ("<Leader>", "Defaults to Space; configurable in vimrc"),
                ("<Leader>w", "Write the current file"),
                ("<Leader>q", "Quit the current window"),
                ("<Leader>Q", "Quit and abandon unsaved changes"),
                ("<Leader>d", "Delete without replacing a register"),
                ("<Leader>r", "Replace word under cursor across file"),
                ("<Leader>lf", "Reindent file or visual selection"),
                ("<Leader>u", "Show built-in undo history"),
            ]),
            ("Yank and clipboard", [
                ("y", "Yank a motion or visual selection"),
                ("yy", "Yank the entire current line"),
                ("Y", "Yank from cursor through line end"),
                ("<Leader>", "Add before y, yy, or Y for system clipboard"),
                ("<Leader><Ctrl-y>", "Yank the entire file"),
                ("Ctrl-c", "Copy line or visual selection (+clipboard)"),
                ("Ctrl-v", "Paste system clipboard (+clipboard)"),
                ("+clipboard", "Leader yanks use system clipboard"),
                ("-clipboard", "Leader yanks use normal register"),
            ]),
            ("Completion and insert", [
                ("Ctrl-n", "Open menu or select next candidate"),
                ("Ctrl-p", "Select previous menu candidate"),
                ("Ctrl-f", "Accept selected completion"),
                ("Esc", "Dismiss menu; otherwise leave Insert mode"),
                ("Enter", "Newline; expands empty pairs/tags"),
                ("() [] {}", "Openers pair; closers move over a match"),
                ("'  \"  >", "Quotes and tag closers are context aware"),
                ("Backspace", "Remove both sides of empty pair/tag"),
            ]),
        ],
        [
            ("Files and help", [
                ("<Leader>f", "Find a file recursively"),
                ("<Leader>b", "Choose an open buffer"),
                ("<Leader>?", "Open Vim help with completion"),
                ("<Leader>cd", "Set window directory to project root"),
            ]),
            ("Search and result lists", [
                ("<Leader>/", "Prompt for project-local git grep"),
                ("<Leader>i", "Grep exact word under cursor"),
                ("<Leader>I", "Open quickfix results"),
                ("[i / ]i", "Previous / next quickfix result"),
                ("[I / ]I", "First / last quickfix result"),
                ("<Leader>O", "Open window location list"),
                ("[o / ]o", "Previous / next location result"),
                ("[O / ]O", "First / last location result"),
                ("[t / ]t", "Previous / next TODO-style note"),
                ("[d / ]d", "Previous / next diff change"),
                ("n / N", "Next / previous search, recentered"),
            ]),
            ("Tags (requires tags file)", [
                ("gd", "Jump if unique; choose if ambiguous"),
                ("gD", "Always list matching definitions first"),
                ("Ctrl-t", "Return from a tag jump"),
            ]),
        ],
        [
            ("Pins (Harpoon-style)", [
                ("mh/mj/mk/ml", "Pin exact location to slot H/J/K/L"),
                ("Ctrl-h/j/k/l", "Jump to the matching pinned location"),
                ("<Leader>h", "List all four pins"),
                ("<Leader>hc", "Clear all four pins"),
            ]),
            ("Netrw essentials", [
                ("<Leader>e", "Open netrw in current window"),
                ("Enter / -", "Open or enter / parent directory"),
                ("Esc", "Return without selecting"),
                ("% / d", "Create file / directory"),
                ("R / D", "Rename / delete"),
                ("i", "Cycle thin, long, wide, and tree views"),
                ("s / r", "Choose sort field / reverse order"),
                ("gh", "Toggle dotfiles"),
                ("mf / mu", "Mark file / clear all marks"),
                ("mt + mc/mm", "Set target, then copy / move marks"),
            ]),
            ("Movement and editing", [
                ("Ctrl-d/u", "Half-page down / up, recentered"),
                ("Visual J/K", "Move selected lines down / up"),
                ("J", "Join lines without losing cursor position"),
            ]),
            ("Useful commands", [
                (":source %", "Reload the current Vim module"),
                (":scriptnames", "Show every sourced Vim script"),
                (":set paste", "Temporarily make permitted paste literal"),
                (":set nopaste", "Restore normal editing after paste"),
                (":make", "Run configured build into quickfix"),
                (":copen", "Open quickfix results"),
                (":earlier", "Move backward through undo history"),
                (":later", "Move forward through undo history"),
            ]),
        ],
    ]

    rendered_columns = []
    for column in columns:
        flowables = []
        for title, entries in column:
            flowables.extend(cheat_category(title, entries, styles))
        rendered_columns.append(flowables)

    story.extend([
        Paragraph("Vim keybinding cheat sheet", styles["cheat_title"]),
        Table(
            [rendered_columns],
            colWidths=[3.18 * inch, 3.18 * inch, 3.18 * inch],
            style=TableStyle([
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 3),
                ("TOPPADDING", (0, 0), (-1, -1), 0),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
            ]),
        ),
    ])


def build_pdf() -> None:
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    styles = make_styles()
    page_width, _ = landscape(letter)
    doc = SimpleDocTemplate(
        str(TMP_PDF), pagesize=landscape(letter),
        leftMargin=0.48 * inch, rightMargin=0.48 * inch,
        topMargin=0.44 * inch, bottomMargin=0.38 * inch,
        title="Closed-intranet Vim setup - printable setup guide",
        author="secure-vim-setup",
        subject="README and complete plugin-free Vim configuration source",
    )
    story: list = []

    story.extend([
        Spacer(1, 0.35 * inch),
        Paragraph("Closed-intranet Vim setup", styles["title"]),
        Paragraph("Printable README and complete retyping copy", styles["subtitle"]),
        Table(
            [[Paragraph(
                "This packet contains the repository instructions followed by every Vim configuration file in the exact order to type them. Code line numbers belong to the guide, not the files.",
                styles["callout"],
            )]],
            colWidths=[page_width - doc.leftMargin - doc.rightMargin],
            style=TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), PALE_BLUE),
                ("BOX", (0, 0), (-1, -1), 0.8, BLUE),
                ("LEFTPADDING", (0, 0), (-1, -1), 12),
                ("RIGHTPADDING", (0, 0), (-1, -1), 12),
                ("TOPPADDING", (0, 0), (-1, -1), 10),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
            ]),
        ),
        Spacer(1, 16),
        Paragraph("Typing order", styles["h2"]),
    ])

    checklist = []
    for index, (display_name, source) in enumerate(CODE_FILES, 1):
        count = len(source.read_text(encoding="utf-8").splitlines())
        checklist.append([
            Paragraph(f"[ ] {index}", styles["body"]),
            Paragraph(f'<font name="Courier">{html.escape(display_name)}</font>', styles["body"]),
            Paragraph(f"{count} lines", styles["body"]),
        ])
    checklist_table = Table(checklist, colWidths=[0.58 * inch, 4.5 * inch, 1.0 * inch], hAlign="LEFT")
    checklist_table.setStyle(TableStyle([
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [WHITE, CODE_BG]),
        ("LINEBELOW", (0, 0), (-1, -1), 0.3, RULE),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    story.extend([
        checklist_table,
        Spacer(1, 13),
        Paragraph("Before using it", styles["h2"]),
        Paragraph(
            "Retype one module at a time. In Vim, run <font name=\"Courier\">:source %</font> after each module and fix the first reported line before continuing. Test the finished setup on a disposable file before using it on controlled source.",
            styles["body"],
        ),
        Spacer(1, 8),
        Paragraph(f"Packet generated {date.today().isoformat()}.", styles["file_meta"]),
        PageBreak(),
    ])

    add_cheat_sheet(story, styles)
    story.append(PageBreak())
    add_markdown(story, (ROOT / "README.md").read_text(encoding="utf-8"), styles)
    story.extend([
        PageBreak(),
        Paragraph("Configuration source", styles["title"]),
        Paragraph(
            "Type the files in the order shown. The shaded LINE column is a proofreading aid and must not be typed. Blank numbered rows are intentional blank lines.",
            styles["subtitle"],
        ),
    ])

    for index, (display_name, source) in enumerate(CODE_FILES):
        if index:
            story.extend([Spacer(1, 14), CondPageBreak(1.6 * inch)])
        count = len(source.read_text(encoding="utf-8").splitlines())
        story.extend([
            KeepTogether([
                Paragraph(display_name, styles["file_title"]),
                Paragraph(f"Source: {source.relative_to(ROOT).as_posix()} - {count} lines", styles["file_meta"]),
            ]),
            code_table(display_name, source, styles),
        ])

    doc.build(story, onFirstPage=page_chrome, onLaterPages=page_chrome)
    shutil.copyfile(TMP_PDF, OUT_PDF)
    print(OUT_PDF)


if __name__ == "__main__":
    build_pdf()
