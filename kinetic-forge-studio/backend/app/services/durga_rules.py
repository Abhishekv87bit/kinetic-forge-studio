import re

_RULES: list[tuple[str, str, str]] = [
    # (error_pattern, description, patch_function_name)
    # Stored as (pattern, description, lambda key) — applied in order
]


def get_repair(error_text: str, source_code: str) -> str | None:
    err = error_text.lower()

    # Rule 1: No pending wires — missing .workplane() before sketch operation
    if "no pending wires" in err or "no pending edges" in err:
        patched = re.sub(
            r"(\.extrude\()",
            r".workplane()\1",
            source_code,
            count=1,
        )
        if patched != source_code:
            return patched

    # Rule 2: Empty STL — explicit export via .val().exportStl()
    if "exportstl" not in source_code.lower() and (
        "empty" in err or "no geometry" in err or "0 bytes" in err
    ):
        patched = source_code.rstrip()
        if "result" in patched or "shape" in patched:
            patched += "\nresult.val().exportStl('output.stl')\n"
            return patched

    # Rule 3: OpenSCAD bracket mismatch — wrap in extra braces and reformat
    if "stderror" in err or ("openscad" in err and "parse error" in err):
        open_c = source_code.count("{")
        close_c = source_code.count("}")
        if open_c > close_c:
            return source_code + "\n" + "}" * (open_c - close_c)
        if close_c > open_c:
            return "{" * (close_c - open_c) + "\n" + source_code

    # Rule 4: CadQuery solid not found — add explicit .solids() selector
    if "no solid found" in err or "tocompound" in err:
        patched = source_code.replace(
            ".val()", ".solids().val()", 1
        )
        if patched != source_code:
            return patched

    # Rule 5: Division by zero / bad parameter — clamp module/teeth to safe defaults
    if "zerodivisionerror" in err or "division by zero" in err:
        patched = re.sub(r"\bmodule\s*=\s*0\b", "module = 1.0", source_code)
        patched = re.sub(r"\bteeth\s*=\s*0\b", "teeth = 20", patched)
        if patched != source_code:
            return patched

    # Rule 6: Import error for cadquery — suggest correct import
    if "importerror" in err and "cadquery" in err:
        if "import cadquery as cq" not in source_code:
            return "import cadquery as cq\n" + source_code

    # Rule 7: Sketch not closed — add .close() before extrude
    if "sketch is not closed" in err or "wire is not closed" in err:
        patched = re.sub(
            r"(\.extrude\()",
            r".close()\1",
            source_code,
            count=1,
        )
        if patched != source_code:
            return patched

    # Rule 8: OpenSCAD missing semicolons — best-effort append
    if "expected ';'" in err:
        lines = source_code.splitlines()
        fixed = []
        for line in lines:
            stripped = line.rstrip()
            if stripped and not stripped.endswith((";", "{", "}", "//", ",")):
                fixed.append(stripped + ";")
            else:
                fixed.append(line)
        patched = "\n".join(fixed)
        if patched != source_code:
            return patched

    # Rule 9: Shape has no volume — add small fillet to degenerate geometry
    if "no volume" in err or "degenerate" in err:
        if ".fillet(" not in source_code and ".chamfer(" not in source_code:
            patched = re.sub(r"(result\s*=\s*.+)", r"\1\nresult = result.edges().fillet(0.01)", source_code, count=1)
            if patched != source_code:
                return patched

    # Rule 10: Workplane selector fails — default to XY
    if "invalid workplane" in err or "selector error" in err:
        patched = re.sub(
            r'\.workplane\(["\'](?!XY|XZ|YZ)[^"\']*["\']\)',
            ".workplane('XY')",
            source_code,
        )
        if patched != source_code:
            return patched

    return None
