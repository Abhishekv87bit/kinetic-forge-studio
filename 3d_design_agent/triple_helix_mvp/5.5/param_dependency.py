#!/usr/bin/env python3
"""
Parameter Dependency Graph — Triple Helix MVP V5.5

Parses config_v5_5.scad and builds a DAG of parameter dependencies.
Answers: "What breaks if I change X?"

Usage:
    python param_dependency.py                     # Summary of all parameters
    python param_dependency.py --impact HEX_R      # What cascades from HEX_R
    python param_dependency.py --impact HEX_R --impact SHAFT_DIA  # Multiple
    python param_dependency.py --deps HOUSING_HEIGHT  # What does HOUSING_HEIGHT depend on
    python param_dependency.py --dot                # Graphviz DOT output
    python param_dependency.py --dot --focus HEX_R  # DOT subgraph from HEX_R
    python param_dependency.py --html               # Interactive HTML visualization
    python param_dependency.py --config path/to/config.scad  # Custom config path
"""

import re
import sys
import os
import argparse
import math
from collections import defaultdict, deque
from pathlib import Path

# ── OpenSCAD built-ins and keywords to exclude from dependency matching ──

BUILTINS = {
    # Math functions
    "sqrt", "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
    "floor", "ceil", "round", "abs", "max", "min", "pow", "exp", "log", "ln",
    "sign", "norm", "cross",
    # String / list
    "len", "str", "chr", "ord", "concat", "lookup", "search",
    # Type
    "is_num", "is_string", "is_list", "is_bool", "is_undef",
    # OpenSCAD keywords
    "for", "if", "else", "let", "each", "true", "false", "undef",
    "function", "module", "include", "use",
    "echo", "assert",
    # Geometry (not relevant in config but safe to exclude)
    "cube", "sphere", "cylinder", "polyhedron", "circle", "square", "polygon",
    "linear_extrude", "rotate_extrude", "hull", "minkowski",
    "union", "difference", "intersection",
    "translate", "rotate", "scale", "mirror", "multmatrix",
    "color", "offset", "projection",
    # Special variables
    "PI",
}

# ── Regex patterns ──

# Match: NAME = expression;  (including multiline with [...] arrays)
RE_ASSIGN = re.compile(
    r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?)\s*;',
    re.MULTILINE | re.DOTALL
)

# Match: function _name(...) = expression;
RE_FUNC_DEF = re.compile(
    r'^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*=\s*(.+?)\s*;',
    re.MULTILINE | re.DOTALL
)

# Match identifiers in expressions
RE_IDENT = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\b')

# Match function calls: name(...)
RE_FUNC_CALL = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\s*\(')

# Match numeric literals (to avoid matching e.g. "3" in identifiers — not needed but useful)
RE_NUMBER = re.compile(r'^[0-9]')


def strip_comments(text):
    """Remove // and /* */ comments from OpenSCAD source."""
    # Remove block comments first
    text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.DOTALL)
    # Remove line comments
    text = re.sub(r'//.*$', '', text, flags=re.MULTILINE)
    return text


def find_matching_bracket(text, start):
    """Find the matching ] for [ at position start."""
    depth = 0
    i = start
    while i < len(text):
        if text[i] == '[':
            depth += 1
        elif text[i] == ']':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return len(text) - 1


def extract_assignments(text):
    """
    Extract all variable assignments and function definitions.
    Returns dict: name -> expression_string
    Handles multiline array comprehensions with [...].
    """
    assignments = {}
    functions = {}
    func_params = {}  # function_name -> set of parameter names

    # First pass: extract function definitions and blank them from text
    # so their bodies don't get picked up as variable assignments
    cleaned_text = text
    for m in RE_FUNC_DEF.finditer(text):
        fname = m.group(1)
        params = m.group(2)
        body = m.group(3)
        functions[fname] = body.strip()
        # Extract parameter names
        param_names = set()
        for p in params.split(','):
            p = p.strip()
            if '=' in p:
                p = p.split('=')[0].strip()
            if p:
                param_names.add(p)
        func_params[fname] = param_names
        # Blank out this function definition so body lines aren't parsed as assignments
        cleaned_text = cleaned_text.replace(m.group(0), ' ' * len(m.group(0)))

    # Second pass: extract variable assignments from cleaned text
    # We need a custom parser because regex struggles with nested brackets
    lines = cleaned_text.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i].strip()

        # Skip empty lines, comments, module/function defs, echo, if, indented lines inside blocks
        if (not line or line.startswith('//') or line.startswith('/*')
                or line.startswith('module ') or line.startswith('function ')
                or line.startswith('echo(') or line.startswith('if (')
                or line.startswith('if(') or line.startswith('}')):
            i += 1
            continue

        # Try to match assignment: NAME = ...
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*', line)
        if m:
            name = m.group(1)
            rest = line[m.end():]

            # Check if the expression is complete (ends with ;)
            full_expr = rest
            # Count brackets to handle multiline
            bracket_depth = full_expr.count('[') - full_expr.count(']')
            paren_depth = full_expr.count('(') - full_expr.count(')')

            while (bracket_depth > 0 or paren_depth > 0) and i + 1 < len(lines):
                i += 1
                next_line = lines[i].strip()
                if next_line.startswith('//'):
                    continue
                full_expr += ' ' + next_line
                bracket_depth = full_expr.count('[') - full_expr.count(']')
                paren_depth = full_expr.count('(') - full_expr.count(')')

            # Remove trailing semicolon
            full_expr = full_expr.rstrip()
            if full_expr.endswith(';'):
                full_expr = full_expr[:-1].rstrip()

            assignments[name] = full_expr

        i += 1

    return assignments, functions, func_params


def find_dependencies(expr, known_params, known_funcs, func_params, exclude_params=None):
    """
    Find all parameter names referenced in an expression.
    Excludes built-ins, function parameter names, and numeric tokens.
    """
    if exclude_params is None:
        exclude_params = set()

    deps = set()
    func_deps = set()

    # Find function calls in expression
    for m in RE_FUNC_CALL.finditer(expr):
        fname = m.group(1)
        if fname in known_funcs and fname not in BUILTINS:
            func_deps.add(fname)

    # Find all identifiers
    for m in RE_IDENT.finditer(expr):
        ident = m.group(1)
        if (ident in known_params
                and ident not in BUILTINS
                and ident not in exclude_params
                and not RE_NUMBER.match(ident)):
            deps.add(ident)

    return deps, func_deps


def try_evaluate(expr, values):
    """
    Try to evaluate an expression given known parameter values.
    Returns (value, success).
    """
    # Build a safe evaluation namespace
    ns = dict(values)
    ns['sqrt'] = math.sqrt
    ns['sin'] = lambda x: math.sin(math.radians(x))
    ns['cos'] = lambda x: math.cos(math.radians(x))
    ns['tan'] = lambda x: math.tan(math.radians(x))
    ns['asin'] = lambda x: math.degrees(math.asin(x))
    ns['acos'] = lambda x: math.degrees(math.acos(x))
    ns['atan'] = lambda x: math.degrees(math.atan(x))
    ns['atan2'] = lambda y, x: math.degrees(math.atan2(y, x))
    ns['floor'] = math.floor
    ns['ceil'] = math.ceil
    ns['round'] = round
    ns['abs'] = abs
    ns['max'] = max
    ns['min'] = min
    ns['pow'] = pow
    ns['PI'] = math.pi
    ns['true'] = True
    ns['false'] = False
    ns['len'] = len

    try:
        val = eval(expr, {"__builtins__": {}}, ns)
        return val, True
    except Exception:
        return None, False


def evaluate_params(assignments, functions, func_params, topo_order):
    """
    Evaluate parameters in topological order to get current values.
    """
    values = {}
    # First evaluate functions (store as callables)
    func_values = {}

    for name in topo_order:
        if name in assignments:
            expr = assignments[name]
            val, ok = try_evaluate(expr, {**values, **func_values})
            if ok:
                values[name] = val
        elif name in functions:
            # Skip function definitions for now — complex to eval
            pass

    return values


def build_graph(assignments, functions, func_params):
    """
    Build the dependency DAG.
    Returns: graph dict { name: { "depends_on": set, "depended_by": set, "expr": str, "is_func": bool } }
    """
    all_params = set(assignments.keys())
    all_funcs = set(functions.keys())
    all_names = all_params | all_funcs

    graph = {}

    # Initialize graph entries for all parameters
    for name in all_params:
        graph[name] = {
            "depends_on": set(),
            "depended_by": set(),
            "expr": assignments[name],
            "is_func": False,
        }

    # Initialize graph entries for all functions
    for name in all_funcs:
        graph[name] = {
            "depends_on": set(),
            "depended_by": set(),
            "expr": functions[name],
            "is_func": True,
        }

    # Build dependency edges
    for name in all_params:
        expr = assignments[name]
        param_deps, func_call_deps = find_dependencies(
            expr, all_params, all_funcs, func_params,
            exclude_params={name}
        )

        # For function calls, add dependencies on the function AND the function's own deps
        for fname in func_call_deps:
            # The parameter depends on whatever the function depends on
            if fname in graph:
                param_deps.add(fname)

        graph[name]["depends_on"] = param_deps

    for name in all_funcs:
        expr = functions[name]
        fparams = func_params.get(name, set())
        param_deps, func_call_deps = find_dependencies(
            expr, all_params | all_funcs, all_funcs, func_params,
            exclude_params=fparams | {name}
        )
        for fname in func_call_deps:
            # Skip self-references (recursive functions)
            if fname != name:
                param_deps.add(fname)
        # Remove self-reference from deps (recursive functions like _cfg_find_V)
        param_deps.discard(name)
        graph[name]["depends_on"] = param_deps

    # Build reverse edges
    for name in graph:
        for dep in graph[name]["depends_on"]:
            if dep in graph:
                graph[dep]["depended_by"].add(name)

    return graph


def topological_sort(graph):
    """
    Kahn's algorithm. Returns sorted list or raises on cycle.
    """
    in_degree = {n: len(graph[n]["depends_on"] & set(graph.keys())) for n in graph}
    queue = deque([n for n, d in in_degree.items() if d == 0])
    result = []

    while queue:
        node = queue.popleft()
        result.append(node)
        for child in graph[node]["depended_by"]:
            if child in in_degree:
                in_degree[child] -= 1
                if in_degree[child] == 0:
                    queue.append(child)

    if len(result) != len(graph):
        remaining = set(graph.keys()) - set(result)
        raise ValueError(f"Cycle detected involving: {remaining}")

    return result


def transitive_dependents(graph, start):
    """
    BFS forward from start. Returns dict: name -> depth_level.
    """
    if start not in graph:
        return {}

    visited = {}
    queue = deque()
    for child in sorted(graph[start]["depended_by"]):
        if child not in visited:
            visited[child] = 1
            queue.append((child, 1))

    while queue:
        node, depth = queue.popleft()
        for child in sorted(graph[node]["depended_by"]):
            if child not in visited:
                visited[child] = depth + 1
                queue.append((child, depth + 1))

    return visited


def transitive_dependencies(graph, start):
    """
    BFS backward from start. Returns dict: name -> depth_level.
    """
    if start not in graph:
        return {}

    visited = {}
    queue = deque()
    for parent in sorted(graph[start]["depends_on"]):
        if parent in graph and parent not in visited:
            visited[parent] = 1
            queue.append((parent, 1))

    while queue:
        node, depth = queue.popleft()
        if node not in graph:
            continue
        for parent in sorted(graph[node]["depends_on"]):
            if parent in graph and parent not in visited:
                visited[parent] = depth + 1
                queue.append((parent, depth + 1))

    return visited


def classify_params(graph):
    """
    Classify parameters into root, hub, leaf, intermediate.
    """
    roots = []
    leaves = []
    hubs = []
    intermediates = []

    for name, info in sorted(graph.items()):
        n_deps_on = len(info["depends_on"] & set(graph.keys()))
        n_deps_by = len(info["depended_by"])

        if n_deps_on == 0:
            roots.append(name)
        if n_deps_by == 0:
            leaves.append(name)

        if n_deps_by >= 4 and n_deps_on > 0:
            hubs.append((name, n_deps_by))

    for name in graph:
        if name not in roots and name not in leaves:
            intermediates.append(name)

    hubs.sort(key=lambda x: -x[1])

    return roots, leaves, hubs, intermediates


def longest_chain(graph):
    """Find the longest dependency chain depth."""
    topo = topological_sort(graph)
    depth = {n: 0 for n in graph}

    for node in topo:
        for child in graph[node]["depended_by"]:
            if child in depth:
                depth[child] = max(depth[child], depth[node] + 1)

    return max(depth.values()) if depth else 0


def format_value(val):
    """Format a value for display."""
    if val is None:
        return "?"
    if isinstance(val, float):
        if val == int(val) and abs(val) < 1e6:
            return str(int(val))
        return f"{val:.2f}"
    if isinstance(val, bool):
        return str(val).lower()
    if isinstance(val, (list, tuple)):
        if len(val) > 6:
            return f"[{format_value(val[0])}..{format_value(val[-1])}] ({len(val)} items)"
        return "[" + ", ".join(format_value(v) for v in val) + "]"
    return str(val)


def truncate_expr(expr, max_len=55):
    """Truncate expression for display."""
    expr = ' '.join(expr.split())  # collapse whitespace
    if len(expr) > max_len:
        return expr[:max_len - 3] + "..."
    return expr


# ── Output: Summary ──

def print_summary(graph, values):
    roots, leaves, hubs, intermediates = classify_params(graph)
    depth = longest_chain(graph)

    n_base = len(roots)
    n_derived = len(graph) - n_base - len([r for r in roots if graph[r]["is_func"]])
    n_funcs = sum(1 for n in graph if graph[n]["is_func"])
    n_leaves = len(leaves)

    print("=" * 60)
    print("PARAMETER DEPENDENCY GRAPH")
    print("Triple Helix MVP V5.5")
    print("=" * 60)
    print()

    # Root parameters
    print("ROOT PARAMETERS (independent design knobs):")
    print("-" * 50)
    root_impact = []
    for name in roots:
        cascade = transitive_dependents(graph, name)
        cascade_count = len(cascade)
        val = values.get(name)
        root_impact.append((name, cascade_count, val))

    root_impact.sort(key=lambda x: -x[1])
    for name, cascade_count, val in root_impact:
        val_str = f" = {format_value(val)}" if val is not None else ""
        tag = " (func)" if graph[name]["is_func"] else ""
        if cascade_count > 0:
            print(f"  {name}{val_str}{tag}")
            print(f"      -> cascades to {cascade_count} downstream param(s)")
        else:
            print(f"  {name}{val_str}{tag}  (terminal)")
    print()

    # Hub parameters
    if hubs:
        print("HUB PARAMETERS (high cascade impact):")
        print("-" * 50)
        for name, n_by in hubs[:15]:
            cascade = transitive_dependents(graph, name)
            val = values.get(name)
            val_str = f" = {format_value(val)}" if val is not None else ""
            expr_str = truncate_expr(graph[name]["expr"])
            print(f"  {name}{val_str}  ({n_by} direct, {len(cascade)} total dependents)")
            print(f"      expr: {expr_str}")
        print()

    # Leaf parameters
    print("LEAF PARAMETERS (final outputs, no downstream deps):")
    print("-" * 50)
    leaf_names = sorted(leaves)
    # Print in columns
    col_w = 30
    for i in range(0, len(leaf_names), 3):
        row = leaf_names[i:i+3]
        print("  " + "  ".join(f"{n:<{col_w}}" for n in row))
    print()

    # Stats
    print("=" * 60)
    print(f"Total: {len(graph)} entries")
    print(f"  {n_base} root params | {n_funcs} functions | {n_derived} derived | {n_leaves} leaves")
    print(f"  Graph depth: {depth} levels (longest chain)")
    print("=" * 60)


# ── Output: Impact Analysis ──

def print_impact(graph, values, param_name):
    if param_name not in graph:
        # Try case-insensitive match
        matches = [n for n in graph if n.lower() == param_name.lower()]
        if matches:
            param_name = matches[0]
        else:
            print(f"ERROR: Parameter '{param_name}' not found in config.")
            close = [n for n in graph if param_name.lower() in n.lower()]
            if close:
                print(f"Did you mean: {', '.join(sorted(close)[:10])}")
            return

    cascade = transitive_dependents(graph, param_name)

    val = values.get(param_name)
    val_str = f" = {format_value(val)}" if val is not None else ""
    expr_str = truncate_expr(graph[param_name]["expr"])

    print()
    print(f"IMPACT ANALYSIS: {param_name}{val_str}")
    print(f"  Expression: {expr_str}")
    print("=" * 60)

    if not cascade:
        deps_on = graph[param_name]["depends_on"] & set(graph.keys())
        print(f"  {param_name} is a LEAF parameter — nothing depends on it.")
        if deps_on:
            print(f"  It depends on: {', '.join(sorted(deps_on))}")
        print()
        return

    print(f"If you change {param_name}, these {len(cascade)} parameters are affected:")
    print()

    # Group by level
    levels = defaultdict(list)
    for name, lvl in cascade.items():
        levels[lvl].append(name)

    for lvl in sorted(levels.keys()):
        names = sorted(levels[lvl])
        label = "direct" if lvl == 1 else f"level {lvl}"
        print(f"  Level {lvl} ({label}):")
        for name in names:
            val = values.get(name)
            val_str = f"  = {format_value(val)}" if val is not None else ""
            expr_str = truncate_expr(graph[name]["expr"], 45)
            tag = " [func]" if graph[name]["is_func"] else ""
            print(f"    {name}{val_str}{tag}")
            print(f"        {expr_str}")
        print()

    print(f"Total affected: {len(cascade)} parameters across {len(levels)} level(s)")
    print()


# ── Output: Deps (upstream) analysis ──

def print_deps(graph, values, param_name):
    if param_name not in graph:
        matches = [n for n in graph if n.lower() == param_name.lower()]
        if matches:
            param_name = matches[0]
        else:
            print(f"ERROR: Parameter '{param_name}' not found in config.")
            return

    ancestry = transitive_dependencies(graph, param_name)

    val = values.get(param_name)
    val_str = f" = {format_value(val)}" if val is not None else ""
    expr_str = truncate_expr(graph[param_name]["expr"])

    print()
    print(f"DEPENDENCY ANALYSIS: {param_name}{val_str}")
    print(f"  Expression: {expr_str}")
    print("=" * 60)

    if not ancestry:
        print(f"  {param_name} is a ROOT parameter — it depends on nothing.")
        by = graph[param_name]["depended_by"]
        if by:
            print(f"  Depended on by: {', '.join(sorted(by))}")
        print()
        return

    print(f"{param_name} ultimately depends on these {len(ancestry)} parameters:")
    print()

    levels = defaultdict(list)
    for name, lvl in ancestry.items():
        levels[lvl].append(name)

    for lvl in sorted(levels.keys()):
        names = sorted(levels[lvl])
        label = "direct" if lvl == 1 else f"level {lvl}"
        print(f"  Level {lvl} ({label}):")
        for name in names:
            val = values.get(name)
            val_str = f"  = {format_value(val)}" if val is not None else ""
            expr_str = truncate_expr(graph[name]["expr"], 45)
            print(f"    {name}{val_str}")
            print(f"        {expr_str}")
        print()


# ── Output: Graphviz DOT ──

def print_dot(graph, focus=None):
    """Output Graphviz DOT format."""
    roots, leaves, hubs, _ = classify_params(graph)
    hub_names = {h[0] for h in hubs}

    # If focus is given, only show the subgraph reachable from focus
    if focus:
        if focus not in graph:
            print(f"// ERROR: '{focus}' not found", file=sys.stderr)
            return
        cascade = transitive_dependents(graph, focus)
        show = {focus} | set(cascade.keys())
    else:
        show = set(graph.keys())

    print("digraph param_deps {")
    print('    rankdir=TB;')
    print('    node [shape=box, fontname="Consolas", fontsize=10];')
    print('    edge [color="#666666"];')
    print()

    for name in sorted(show):
        info = graph[name]
        # Color coding
        if name in roots:
            color = "#c8e6c9"  # green
            style = "filled"
        elif name in hub_names:
            color = "#fff9c4"  # yellow
            style = "filled"
        elif name in leaves:
            color = "#e0e0e0"  # gray
            style = "filled"
        else:
            color = "#ffffff"
            style = "filled"

        if info["is_func"]:
            shape = "ellipse"
        else:
            shape = "box"

        label = name.replace('"', '\\"')
        print(f'    "{label}" [shape={shape}, style="{style}", fillcolor="{color}"];')

    print()

    for name in sorted(show):
        for dep in sorted(graph[name]["depends_on"]):
            if dep in show and dep in graph:
                print(f'    "{dep}" -> "{name}";')

    print("}")


# ── Output: Interactive HTML ──

def print_html(graph, values):
    """Generate a self-contained interactive HTML visualization."""
    roots, leaves, hubs, _ = classify_params(graph)
    hub_names = {h[0] for h in hubs}

    # Build JSON data for JavaScript
    nodes = []
    for name in sorted(graph.keys()):
        info = graph[name]
        val = values.get(name)
        cascade = transitive_dependents(graph, name)
        n_deps_on = len(info["depends_on"] & set(graph.keys()))
        n_deps_by = len(info["depended_by"])

        if name in roots:
            category = "root"
        elif name in hub_names:
            category = "hub"
        elif name in leaves:
            category = "leaf"
        else:
            category = "intermediate"

        nodes.append({
            "name": name,
            "expr": truncate_expr(info["expr"], 80),
            "value": format_value(val) if val is not None else "?",
            "category": category,
            "is_func": info["is_func"],
            "depends_on": sorted(info["depends_on"] & set(graph.keys())),
            "depended_by": sorted(info["depended_by"]),
            "cascade_count": len(cascade),
            "depth_up": n_deps_on,
        })

    import json
    nodes_json = json.dumps(nodes, indent=2)

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Parameter Dependency Graph - Triple Helix V5.5</title>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ font-family: 'Segoe UI', Consolas, monospace; background: #1a1a2e; color: #e0e0e0; }}
.header {{ background: #16213e; padding: 16px 24px; border-bottom: 2px solid #0f3460; }}
.header h1 {{ font-size: 18px; color: #e94560; }}
.header p {{ font-size: 12px; color: #888; margin-top: 4px; }}
.container {{ display: flex; height: calc(100vh - 80px); }}
.sidebar {{ width: 320px; background: #16213e; overflow-y: auto; border-right: 1px solid #0f3460; }}
.main {{ flex: 1; overflow-y: auto; padding: 20px; }}
.search {{ padding: 10px; }}
.search input {{ width: 100%; padding: 8px; background: #1a1a2e; border: 1px solid #0f3460;
    color: #e0e0e0; font-family: inherit; font-size: 13px; border-radius: 4px; }}
.search input::placeholder {{ color: #555; }}
.category {{ padding: 6px 12px; font-size: 11px; color: #888; text-transform: uppercase;
    letter-spacing: 1px; margin-top: 8px; }}
.param-item {{ padding: 6px 12px; cursor: pointer; font-size: 13px; border-left: 3px solid transparent; }}
.param-item:hover {{ background: #1a1a3e; }}
.param-item.selected {{ background: #1a1a3e; border-left-color: #e94560; }}
.param-item .name {{ font-weight: bold; }}
.param-item .cascade {{ font-size: 11px; color: #666; margin-left: 8px; }}
.param-item.root .name {{ color: #66bb6a; }}
.param-item.hub .name {{ color: #fdd835; }}
.param-item.leaf .name {{ color: #999; }}
.param-item.intermediate .name {{ color: #b0bec5; }}
.param-item.func .name {{ font-style: italic; }}
.detail {{ max-width: 900px; }}
.detail h2 {{ color: #e94560; font-size: 20px; margin-bottom: 4px; }}
.detail .expr {{ color: #81d4fa; font-size: 14px; margin: 8px 0; padding: 8px;
    background: #0d1b2a; border-radius: 4px; font-family: Consolas, monospace; word-break: break-all; }}
.detail .value {{ color: #a5d6a7; font-size: 14px; margin-bottom: 12px; }}
.detail .badge {{ display: inline-block; padding: 2px 8px; border-radius: 10px;
    font-size: 11px; font-weight: bold; margin-right: 6px; }}
.badge.root {{ background: #1b5e20; color: #a5d6a7; }}
.badge.hub {{ background: #f9a825; color: #333; }}
.badge.leaf {{ background: #424242; color: #bbb; }}
.badge.intermediate {{ background: #263238; color: #90a4ae; }}
.dep-section {{ margin-top: 16px; }}
.dep-section h3 {{ font-size: 14px; color: #90caf9; margin-bottom: 8px; }}
.dep-list {{ list-style: none; }}
.dep-list li {{ padding: 4px 0; font-size: 13px; cursor: pointer; }}
.dep-list li:hover {{ color: #e94560; }}
.dep-list li .level {{ color: #666; font-size: 11px; margin-left: 8px; }}
.dep-list li .val {{ color: #81c784; font-size: 12px; margin-left: 6px; }}
.no-selection {{ color: #555; font-size: 16px; margin-top: 40px; text-align: center; }}
.stats {{ padding: 10px 12px; font-size: 11px; color: #555; border-top: 1px solid #0f3460; }}
</style>
</head>
<body>
<div class="header">
    <h1>Parameter Dependency Graph</h1>
    <p>Triple Helix MVP V5.5 -- click a parameter to see impact analysis</p>
</div>
<div class="container">
    <div class="sidebar">
        <div class="search">
            <input type="text" id="searchBox" placeholder="Search parameters..." />
        </div>
        <div id="paramList"></div>
        <div class="stats" id="stats"></div>
    </div>
    <div class="main">
        <div class="detail" id="detail">
            <div class="no-selection">Select a parameter from the sidebar</div>
        </div>
    </div>
</div>

<script>
const nodes = {nodes_json};

const nodeMap = {{}};
nodes.forEach(n => nodeMap[n.name] = n);

function getTransitiveDeps(name, direction) {{
    const visited = {{}};
    const queue = [];
    const start = nodeMap[name];
    if (!start) return visited;

    const neighbors = direction === 'down' ? start.depended_by : start.depends_on;
    neighbors.forEach(n => {{
        if (!(n in visited) && n in nodeMap) {{
            visited[n] = 1;
            queue.push([n, 1]);
        }}
    }});

    while (queue.length > 0) {{
        const [node, depth] = queue.shift();
        const info = nodeMap[node];
        if (!info) continue;
        const next = direction === 'down' ? info.depended_by : info.depends_on;
        next.forEach(n => {{
            if (!(n in visited) && n in nodeMap) {{
                visited[n] = depth + 1;
                queue.push([n, depth + 1]);
            }}
        }});
    }}

    return visited;
}}

function renderList(filter) {{
    const list = document.getElementById('paramList');
    list.innerHTML = '';

    const categories = ['root', 'hub', 'intermediate', 'leaf'];
    const labels = {{ root: 'Root Parameters', hub: 'Hub Parameters',
                     intermediate: 'Intermediate', leaf: 'Leaf Parameters' }};

    categories.forEach(cat => {{
        const items = nodes.filter(n => n.category === cat &&
            (!filter || n.name.toLowerCase().includes(filter.toLowerCase())));
        if (items.length === 0) return;

        const heading = document.createElement('div');
        heading.className = 'category';
        heading.textContent = labels[cat] + ' (' + items.length + ')';
        list.appendChild(heading);

        items.forEach(item => {{
            const div = document.createElement('div');
            div.className = 'param-item ' + item.category + (item.is_func ? ' func' : '');
            div.innerHTML = '<span class="name">' + item.name + '</span>' +
                (item.cascade_count > 0 ? '<span class="cascade">' + item.cascade_count + ' downstream</span>' : '');
            div.onclick = () => selectParam(item.name);
            div.id = 'item-' + item.name;
            list.appendChild(div);
        }});
    }});
}}

function selectParam(name) {{
    document.querySelectorAll('.param-item.selected').forEach(el => el.classList.remove('selected'));
    const el = document.getElementById('item-' + name);
    if (el) el.classList.add('selected');

    const node = nodeMap[name];
    if (!node) return;

    const downDeps = getTransitiveDeps(name, 'down');
    const upDeps = getTransitiveDeps(name, 'up');

    let html = '<div class="badge ' + node.category + '">' + node.category.toUpperCase() + '</div>';
    if (node.is_func) html += '<div class="badge intermediate">FUNCTION</div>';
    html += '<h2>' + name + '</h2>';
    html += '<div class="value">Current value: ' + node.value + '</div>';
    html += '<div class="expr">' + escapeHtml(node.expr) + '</div>';

    // Downstream
    const downEntries = Object.entries(downDeps).sort((a,b) => a[1] - b[1] || a[0].localeCompare(b[0]));
    html += '<div class="dep-section">';
    html += '<h3>Downstream Impact (' + downEntries.length + ' affected if changed)</h3>';
    if (downEntries.length > 0) {{
        html += '<ul class="dep-list">';
        let currentLevel = 0;
        downEntries.forEach(([n, level]) => {{
            if (level !== currentLevel) {{
                currentLevel = level;
                html += '<li style="color:#666; font-style:italic; padding-top:8px;">Level ' + level +
                    (level === 1 ? ' (direct)' : '') + '</li>';
            }}
            const ni = nodeMap[n];
            html += '<li onclick="selectParam(\\''+n+'\\')"><span class="name">' + n + '</span>' +
                '<span class="val">' + (ni ? ni.value : '?') + '</span></li>';
        }});
        html += '</ul>';
    }} else {{
        html += '<p style="color:#555; font-size:13px;">No downstream dependents (leaf parameter)</p>';
    }}
    html += '</div>';

    // Upstream
    const upEntries = Object.entries(upDeps).sort((a,b) => a[1] - b[1] || a[0].localeCompare(b[0]));
    html += '<div class="dep-section">';
    html += '<h3>Upstream Dependencies (' + upEntries.length + ' ancestors)</h3>';
    if (upEntries.length > 0) {{
        html += '<ul class="dep-list">';
        let currentLevel = 0;
        upEntries.forEach(([n, level]) => {{
            if (level !== currentLevel) {{
                currentLevel = level;
                html += '<li style="color:#666; font-style:italic; padding-top:8px;">Level ' + level +
                    (level === 1 ? ' (direct)' : '') + '</li>';
            }}
            const ni = nodeMap[n];
            html += '<li onclick="selectParam(\\''+n+'\\')"><span class="name">' + n + '</span>' +
                '<span class="val">' + (ni ? ni.value : '?') + '</span></li>';
        }});
        html += '</ul>';
    }} else {{
        html += '<p style="color:#555; font-size:13px;">No upstream dependencies (root parameter)</p>';
    }}
    html += '</div>';

    document.getElementById('detail').innerHTML = html;
}}

function escapeHtml(s) {{
    return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}}

// Init
renderList('');
document.getElementById('searchBox').addEventListener('input', e => renderList(e.target.value));
document.getElementById('stats').textContent =
    nodes.length + ' params | ' +
    nodes.filter(n=>n.category==='root').length + ' roots | ' +
    nodes.filter(n=>n.category==='leaf').length + ' leaves';

// Auto-select first root
const firstRoot = nodes.find(n => n.category === 'root' && n.cascade_count > 0);
if (firstRoot) selectParam(firstRoot.name);
</script>
</body>
</html>"""

    print(html)


# ── Main ──

def main():
    parser = argparse.ArgumentParser(
        description="Parameter Dependency Graph for Triple Helix MVP V5.5",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python param_dependency.py                     Summary of all parameters
  python param_dependency.py --impact HEX_R      What cascades from HEX_R
  python param_dependency.py --deps HOUSING_HEIGHT  What HOUSING_HEIGHT depends on
  python param_dependency.py --dot                Graphviz DOT output
  python param_dependency.py --dot --focus HEX_R  DOT subgraph from HEX_R
  python param_dependency.py --html               Interactive HTML visualization
  python param_dependency.py --list-roots         Just list root parameters
  python param_dependency.py --list-leaves        Just list leaf parameters
        """
    )

    parser.add_argument("--config", type=str, default=None,
                        help="Path to config .scad file (default: config_v5_5.scad in same directory)")
    parser.add_argument("--impact", type=str, action="append", metavar="PARAM",
                        help="Show impact analysis for PARAM (can be repeated)")
    parser.add_argument("--deps", type=str, action="append", metavar="PARAM",
                        help="Show upstream dependencies for PARAM (can be repeated)")
    parser.add_argument("--dot", action="store_true",
                        help="Output Graphviz DOT format")
    parser.add_argument("--focus", type=str, default=None,
                        help="Focus DOT output on subgraph from this parameter")
    parser.add_argument("--html", action="store_true",
                        help="Output interactive HTML visualization")
    parser.add_argument("--list-roots", action="store_true",
                        help="List root parameters only")
    parser.add_argument("--list-leaves", action="store_true",
                        help="List leaf parameters only")
    parser.add_argument("--list-hubs", action="store_true",
                        help="List hub parameters only")

    args = parser.parse_args()

    # Find config file
    if args.config:
        config_path = Path(args.config)
    else:
        script_dir = Path(__file__).parent
        config_path = script_dir / "config_v5_5.scad"
        if not config_path.exists():
            # Try check point directory
            config_path = script_dir.parent / "check point" / "5.5" / "config_v5_5.scad"

    if not config_path.exists():
        print(f"ERROR: Config file not found: {config_path}", file=sys.stderr)
        print("Use --config to specify the path.", file=sys.stderr)
        sys.exit(1)

    # Read and parse
    text = config_path.read_text(encoding="utf-8")
    text = strip_comments(text)

    assignments, functions, func_params = extract_assignments(text)

    if not assignments and not functions:
        print("ERROR: No parameters found in config file.", file=sys.stderr)
        sys.exit(1)

    # Build graph
    graph = build_graph(assignments, functions, func_params)

    # Verify acyclic
    try:
        topo_order = topological_sort(graph)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    # Evaluate current values
    values = evaluate_params(assignments, functions, func_params, topo_order)

    # Output
    if args.dot:
        print_dot(graph, focus=args.focus)
    elif args.html:
        print_html(graph, values)
    elif args.impact:
        for param in args.impact:
            print_impact(graph, values, param)
    elif args.deps:
        for param in args.deps:
            print_deps(graph, values, param)
    elif args.list_roots:
        roots, _, _, _ = classify_params(graph)
        for name in sorted(roots):
            val = values.get(name)
            cascade = transitive_dependents(graph, name)
            val_str = f" = {format_value(val)}" if val is not None else ""
            print(f"{name}{val_str}  ({len(cascade)} downstream)")
    elif args.list_leaves:
        _, leaves, _, _ = classify_params(graph)
        for name in sorted(leaves):
            val = values.get(name)
            val_str = f" = {format_value(val)}" if val is not None else ""
            print(f"{name}{val_str}")
    elif args.list_hubs:
        _, _, hubs, _ = classify_params(graph)
        for name, n_by in hubs:
            val = values.get(name)
            cascade = transitive_dependents(graph, name)
            val_str = f" = {format_value(val)}" if val is not None else ""
            print(f"{name}{val_str}  ({n_by} direct, {len(cascade)} total)")
    else:
        print_summary(graph, values)


if __name__ == "__main__":
    main()
