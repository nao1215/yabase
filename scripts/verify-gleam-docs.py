#!/usr/bin/env python3
"""Compile documented Gleam modules in an isolated copy and execute their mains."""

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def extract_blocks(document):
    blocks = []
    fence = None
    gleam = False
    content = []
    for line in document.splitlines(keepends=True):
        match = re.match(r"^ {0,3}(`{3,}|~{3,})([^\r\n]*)[\r\n]*$", line)
        if fence is None:
            if match:
                fence = match[1]
                gleam = match[2].strip() == "gleam"
                content = []
            continue
        if match and match[1][0] == fence[0] and len(match[1]) >= len(fence):
            if match[2].strip():
                raise ValueError("a fence opened before the previous fence closed")
            if gleam:
                blocks.append("".join(content))
            fence = None
        elif gleam:
            content.append(line)
    if fence is not None:
        raise ValueError("unclosed fenced code block")
    if not blocks:
        raise ValueError("README contains no Gleam code blocks")
    return blocks


def module_source(block):
    if not block.strip():
        raise ValueError("empty Gleam code block")
    declarations = r"(?m)^\s*(?:pub\s+)?(?:fn|(?:opaque\s+)?type|const)\s+"
    if re.search(declarations, block):
        return block, bool(re.search(r"(?m)^\s*pub\s+fn\s+main\s*\(", block))
    # Import declarations may span several lines; retain source bytes and escapes.
    imports, body = [], []
    importing = False
    depth = 0
    for line in block.splitlines(keepends=True):
        if importing or re.match(r"^\s*import\s+", line):
            imports.append(line)
            depth += line.count("{") - line.count("}")
            importing = depth > 0
        else:
            body.append(line)
    if importing:
        raise ValueError("unclosed import in expression block")
    return "".join(imports) + "\npub fn main() {\n" + "".join(body) + "\n}\n", True


def verify(root, modules):
    with tempfile.TemporaryDirectory(prefix="yabase-doc-check-") as directory:
        project = Path(directory)
        for name in ("gleam.toml", "manifest.toml"):
            shutil.copy2(root / name, project / name)
        shutil.copytree(root / "src", project / "src")
        # Reuse downloaded sources without writing to the checkout or sharing build output.
        cached = root / "build" / "packages"
        if not cached.is_dir():
            raise ValueError("download dependencies with `gleam deps download` first")
        shutil.copytree(cached, project / "build" / "packages")
        for name, source, _ in modules:
            (project / "src" / f"{name}.gleam").write_text(source)
        for target in ("erlang", "javascript"):
            subprocess.run(["gleam", "build", "--warnings-as-errors", "--target", target],
                           cwd=project, check=True)
            for name, _, runnable in modules:
                if runnable:
                    subprocess.run(["gleam", "run", "--target", target, "-m", name],
                                   cwd=project, check=True)
    runnable_count = sum(runnable for _, _, runnable in modules)
    print(f"Both targets: {len(modules)} modules compiled; "
          f"{runnable_count} main functions executed; "
          f"{len(modules) - runnable_count} compile-only modules.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--readme", type=Path)
    group.add_argument("--examples", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    if args.examples:
        paths = sorted((root / "examples").glob("*.gleam"))
        if not paths:
            raise ValueError("no example modules found")
        modules = []
        for index, path in enumerate(paths, 1):
            source, runnable = module_source(path.read_text())
            if not runnable:
                raise ValueError(f"example {path.name} has no public main function")
            modules.append((f"checked_example_{index}", source, runnable))
    else:
        document = (args.readme or root / "README.md").read_text()
        modules = [(f"checked_readme_{index}", *module_source(block))
                   for index, block in enumerate(extract_blocks(document), 1)]
    verify(root, modules)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from error
