param(
    [Parameter(Mandatory = $true)]
    [string]$BaselinePath,

    [Parameter(Mandatory = $true)]
    [string]$RevisedPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [string]$Author = "Codex"
)

$ErrorActionPreference = "Stop"

$resolvedBaseline = Resolve-Path -LiteralPath $BaselinePath
$resolvedRevised = Resolve-Path -LiteralPath $RevisedPath

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCommand) {
    throw "Python was not found on PATH. This script requires the standard-library zipfile/xml/difflib modules."
}

$pythonScript = Join-Path $env:TEMP ("word_track_changes_" + [guid]::NewGuid().ToString("N") + ".py")

$pythonSource = @'
import argparse
import copy
import datetime as dt
import os
import re
import shutil
import tempfile
import zipfile
import difflib
import xml.etree.ElementTree as ET

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
XML = "{http://www.w3.org/XML/1998/namespace}"
MC = "{http://schemas.openxmlformats.org/markup-compatibility/2006}"

ET.register_namespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
ET.register_namespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
ET.register_namespace("wp", "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing")
ET.register_namespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
ET.register_namespace("pic", "http://schemas.openxmlformats.org/drawingml/2006/picture")


def register_namespaces_from_file(path):
    for _, namespace in ET.iterparse(path, events=("start-ns",)):
        prefix, uri = namespace
        if prefix == "xml":
            continue
        try:
            ET.register_namespace(prefix or "", uri)
        except ValueError:
            # ElementTree rejects reserved prefixes. Leave them untouched rather
            # than aborting a Word export for a namespace we do not edit.
            pass


def namespace_map_from_file(path):
    namespace_map = {}
    for _, namespace in ET.iterparse(path, events=("start-ns",)):
        prefix, uri = namespace
        if prefix:
            namespace_map[prefix] = uri
    return namespace_map


def namespace_uri(name):
    if name.startswith("{") and "}" in name:
        return name[1:].split("}", 1)[0]
    return None


def used_namespace_uris(root):
    used = set()
    for node in root.iter():
        uri = namespace_uri(node.tag)
        if uri:
            used.add(uri)
        for attr in node.attrib:
            uri = namespace_uri(attr)
            if uri:
                used.add(uri)
    return used


def filter_mc_ignorable(root, namespace_map):
    used = used_namespace_uris(root)
    for node in root.iter():
        value = node.attrib.get(MC + "Ignorable")
        if not value:
            continue
        kept = []
        for prefix in value.split():
            uri = namespace_map.get(prefix)
            if uri and uri in used:
                kept.append(prefix)
        if kept:
            node.set(MC + "Ignorable", " ".join(kept))
        else:
            del node.attrib[MC + "Ignorable"]


def unzip(path, target):
    with zipfile.ZipFile(path, "r") as zf:
        zf.extractall(target)


def zip_dir(source, output):
    if os.path.exists(output):
        os.remove(output)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(source):
            for name in files:
                full = os.path.join(root, name)
                rel = os.path.relpath(full, source)
                zf.write(full, rel)


def para_text(p):
    parts = []
    for node in p.iter():
        if node.tag in (W + "t", W + "instrText", W + "delText"):
            parts.append(node.text or "")
    return "".join(parts)


def norm(s):
    return re.sub(r"\s+", " ", s or "").strip()


def has_drawing(p):
    for node in p.iter():
        if node.tag == W + "drawing":
            return True
    return False


def tokenize(s):
    return re.findall(r"\s+|[^\s]+", s or "")


def make_t(parent, tag, text):
    t = ET.SubElement(parent, W + tag)
    t.text = text
    if text.startswith(" ") or text.endswith(" ") or re.fullmatch(r"\s+", text or ""):
        t.set(XML + "space", "preserve")
    return t


def append_plain_run(p, text):
    if text == "":
        return
    r = ET.SubElement(p, W + "r")
    make_t(r, "t", text)


def append_revision(p, kind, text, author, date, rev_id):
    if text == "":
        return rev_id
    node = ET.SubElement(p, W + kind)
    node.set(W + "id", str(rev_id))
    node.set(W + "author", author)
    node.set(W + "date", date)
    r = ET.SubElement(node, W + "r")
    make_t(r, "delText" if kind == "del" else "t", text)
    return rev_id + 1


def set_tracked_para(p, old_text, new_text, author, date, rev_id):
    ppr = None
    for child in list(p):
        if child.tag == W + "pPr":
            ppr = child
            break

    for child in list(p):
        if child is ppr:
            continue
        p.remove(child)

    old_tokens = tokenize(old_text)
    new_tokens = tokenize(new_text)
    matcher = difflib.SequenceMatcher(None, old_tokens, new_tokens, autojunk=False)

    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            append_plain_run(p, "".join(new_tokens[j1:j2]))
        elif tag == "delete":
            rev_id = append_revision(p, "del", "".join(old_tokens[i1:i2]), author, date, rev_id)
        elif tag == "insert":
            rev_id = append_revision(p, "ins", "".join(new_tokens[j1:j2]), author, date, rev_id)
        elif tag == "replace":
            rev_id = append_revision(p, "del", "".join(old_tokens[i1:i2]), author, date, rev_id)
            rev_id = append_revision(p, "ins", "".join(new_tokens[j1:j2]), author, date, rev_id)
    return rev_id


def set_inserted_para(p, new_text, author, date, rev_id):
    ppr = None
    for child in list(p):
        if child.tag == W + "pPr":
            ppr = child
            break

    for child in list(p):
        if child is ppr:
            continue
        p.remove(child)

    return append_revision(p, "ins", new_text, author, date, rev_id)


def ensure_track_revisions(settings_path):
    if not os.path.exists(settings_path):
        return False
    namespace_map = namespace_map_from_file(settings_path)
    register_namespaces_from_file(settings_path)
    tree = ET.parse(settings_path)
    root = tree.getroot()
    if root.find(W + "trackRevisions") is None:
        ET.SubElement(root, W + "trackRevisions")
        filter_mc_ignorable(root, namespace_map)
        tree.write(settings_path, encoding="utf-8", xml_declaration=True)
        return True
    filter_mc_ignorable(root, namespace_map)
    tree.write(settings_path, encoding="utf-8", xml_declaration=True)
    return False


def remove_body_level_bookmarks(root):
    body = root.find(W + "body")
    if body is None:
        return 0
    removed = 0
    for child in list(body):
        if child.tag in (W + "bookmarkStart", W + "bookmarkEnd"):
            body.remove(child)
            removed += 1
    return removed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--revised", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--author", default="Codex")
    args = parser.parse_args()

    tmp = tempfile.mkdtemp(prefix="word_track_changes_")
    old_root = os.path.join(tmp, "old")
    new_root = os.path.join(tmp, "new")
    os.makedirs(old_root)
    os.makedirs(new_root)

    try:
        unzip(args.baseline, old_root)
        unzip(args.revised, new_root)

        old_doc_path = os.path.join(old_root, "word", "document.xml")
        new_doc_path = os.path.join(new_root, "word", "document.xml")

        new_namespace_map = namespace_map_from_file(new_doc_path)
        register_namespaces_from_file(new_doc_path)
        old_tree = ET.parse(old_doc_path)
        new_tree = ET.parse(new_doc_path)
        old_root_xml = old_tree.getroot()
        new_root_xml = new_tree.getroot()
        removed_body_bookmarks = remove_body_level_bookmarks(new_root_xml)

        old_paras = list(old_root_xml.iter(W + "p"))
        new_paras = list(new_root_xml.iter(W + "p"))
        old_norms = [norm(para_text(p)) for p in old_paras]
        new_norms = [norm(para_text(p)) for p in new_paras]

        date = dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        rev_id = 1
        changed = 0
        skipped_drawing_changes = 0
        inserted_paragraphs = 0
        skipped_inserted_drawing_paragraphs = 0
        skipped_deleted_paragraphs = 0

        paragraph_matcher = difflib.SequenceMatcher(None, old_norms, new_norms, autojunk=False)

        for opcode, i1, i2, j1, j2 in paragraph_matcher.get_opcodes():
            if opcode == "equal":
                continue
            if opcode == "delete":
                skipped_deleted_paragraphs += (i2 - i1)
                continue
            if opcode == "insert":
                for new_p in new_paras[j1:j2]:
                    if has_drawing(new_p):
                        skipped_inserted_drawing_paragraphs += 1
                        continue
                    rev_id = set_inserted_para(new_p, para_text(new_p), args.author, date, rev_id)
                    inserted_paragraphs += 1
                continue

            old_block = old_paras[i1:i2]
            new_block = new_paras[j1:j2]
            paired = min(len(old_block), len(new_block))

            for offset in range(paired):
                old_p = old_block[offset]
                new_p = new_block[offset]
                old_text = para_text(old_p)
                new_text = para_text(new_p)
                if norm(old_text) == norm(new_text):
                    continue
                if has_drawing(new_p) or has_drawing(old_p):
                    skipped_drawing_changes += 1
                    continue
                rev_id = set_tracked_para(new_p, old_text, new_text, args.author, date, rev_id)
                changed += 1

            for new_p in new_block[paired:]:
                if has_drawing(new_p):
                    skipped_inserted_drawing_paragraphs += 1
                    continue
                rev_id = set_inserted_para(new_p, para_text(new_p), args.author, date, rev_id)
                inserted_paragraphs += 1

            if len(old_block) > paired:
                skipped_deleted_paragraphs += (len(old_block) - paired)

        filter_mc_ignorable(new_root_xml, new_namespace_map)
        new_tree.write(new_doc_path, encoding="utf-8", xml_declaration=True)
        ensure_track_revisions(os.path.join(new_root, "word", "settings.xml"))
        zip_dir(new_root, args.output)

        print(f"output={args.output}")
        print(f"changed_paragraphs={changed}")
        print(f"inserted_paragraphs_marked={inserted_paragraphs}")
        print(f"skipped_drawing_changes={skipped_drawing_changes}")
        print(f"skipped_inserted_drawing_paragraphs={skipped_inserted_drawing_paragraphs}")
        print(f"skipped_deleted_paragraphs={skipped_deleted_paragraphs}")
        print(f"removed_body_level_bookmarks={removed_body_bookmarks}")
        print(f"revision_nodes_created={rev_id - 1}")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
'@

Set-Content -LiteralPath $pythonScript -Value $pythonSource -Encoding UTF8

try {
    & $pythonCommand.Source $pythonScript `
        --baseline $resolvedBaseline.Path `
        --revised $resolvedRevised.Path `
        --output $OutputPath `
        --author $Author

    if ($LASTEXITCODE -ne 0) {
        throw "Word tracked-changes generation failed with exit code $LASTEXITCODE."
    }
}
finally {
    Remove-Item -LiteralPath $pythonScript -Force -ErrorAction SilentlyContinue
}
