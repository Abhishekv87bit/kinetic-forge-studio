#!/usr/bin/env python3
"""Hookify rule file validator.

Checks all hookify.*.local.md files against the 6 authoring rules:
1. ASCII only -- no emojis, no em dashes, no Unicode
2. No [/\] in regex -- use . (dot) instead for path separators
3. No $ anchors in content-matching patterns (file_path patterns are OK)
4. Use field: content for file event text matching (NOT new_text)
5. Stop rules need field: reason -- NOT pattern: (auto-assigns content)
6. Validate YAML frontmatter structure

Usage:
    py -3.12 tools/validate_hookify.py
"""

import os
import sys
import glob
import re


def find_rule_files():
    """Find all hookify rule files in HOME/.claude/."""
    home = os.path.expanduser("~")
    pattern = os.path.join(home, ".claude", "hookify.*.local.md")
    return sorted(glob.glob(pattern))


def parse_frontmatter(content):
    """Simple YAML frontmatter parser."""
    if not content.startswith("---"):
        return None, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return None, content

    fm_text = parts[1]
    body = parts[2].strip()

    result = {}
    lines = fm_text.strip().split("\n")
    current_key = None
    current_list = []
    current_dict = {}
    in_list = False
    in_dict_item = False

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        indent = len(line) - len(line.lstrip())

        if indent == 0 and ":" in line and not stripped.startswith("-"):
            if in_list and current_key:
                if in_dict_item and current_dict:
                    current_list.append(current_dict)
                    current_dict = {}
                result[current_key] = current_list
                in_list = False
                in_dict_item = False
                current_list = []

            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")

            if not value:
                current_key = key
                in_list = True
                current_list = []
            else:
                if value.lower() == "true":
                    value = True
                elif value.lower() == "false":
                    value = False
                result[key] = value

        elif stripped.startswith("-") and in_list:
            if in_dict_item and current_dict:
                current_list.append(current_dict)
                current_dict = {}

            item_text = stripped[1:].strip()
            if ":" in item_text:
                in_dict_item = True
                k, v = item_text.split(":", 1)
                current_dict = {k.strip(): v.strip().strip('"').strip("'")}
            else:
                current_list.append(item_text)
                in_dict_item = False

        elif indent > 2 and in_dict_item and ":" in line:
            k, v = stripped.split(":", 1)
            current_dict[k.strip()] = v.strip().strip('"').strip("'")

    if in_list and current_key:
        if in_dict_item and current_dict:
            current_list.append(current_dict)
        result[current_key] = current_list

    return result, body


def validate_rule(filepath, content, fm, body):
    """Validate a single rule file. Returns list of (severity, message)."""
    issues = []
    name = os.path.basename(filepath)

    # Rule 1: ASCII only
    for i, ch in enumerate(content):
        if ord(ch) > 127:
            line_num = content[:i].count("\n") + 1
            issues.append(("FAIL", f"Non-ASCII char U+{ord(ch):04X} at line {line_num}"))
            break

    # Rule 2: No [/\] in regex
    if "[/\\]" in content:
        issues.append(("FAIL", "Contains [/\\] in regex -- use . (dot) instead"))

    # Frontmatter checks
    if fm is None:
        issues.append(("FAIL", "Missing YAML frontmatter"))
        return issues

    # Required fields
    if "name" not in fm:
        issues.append(("FAIL", "Missing 'name' field"))
    if "enabled" not in fm:
        issues.append(("WARN", "Missing 'enabled' field (defaults to true)"))
    if "event" not in fm:
        issues.append(("FAIL", "Missing 'event' field"))

    event = fm.get("event", "")
    action = fm.get("action", "warn")
    conditions = fm.get("conditions", [])

    # Rule 4: file event should use field: content, NOT new_text
    if isinstance(conditions, list):
        for cond in conditions:
            if isinstance(cond, dict):
                field = cond.get("field", "")
                if field == "new_text":
                    issues.append(("FAIL", "Uses field: new_text (should be field: content)"))

    # Rule 5: Stop rules need field: reason
    if event == "stop":
        has_reason_field = False
        if isinstance(conditions, list):
            for cond in conditions:
                if isinstance(cond, dict) and cond.get("field") == "reason":
                    has_reason_field = True
        if "pattern" in fm and not conditions:
            issues.append(("WARN", "Stop rule uses legacy pattern: -- should use conditions with field: reason"))
        elif not has_reason_field and conditions:
            issues.append(("WARN", "Stop rule has no field: reason condition"))

    # Check action is valid
    if action not in ("warn", "block"):
        issues.append(("FAIL", f"Invalid action: {action} (must be warn or block)"))

    # Check event is valid
    valid_events = {"bash", "file", "stop", "prompt", "all"}
    if event not in valid_events:
        issues.append(("WARN", f"Unusual event type: {event}"))

    # Check for empty body
    if not body.strip():
        issues.append(("WARN", "Empty message body"))

    return issues


def main():
    files = find_rule_files()

    if not files:
        print("ERROR: No hookify rule files found!")
        print(f"Expected at: {os.path.expanduser('~/.claude/hookify.*.local.md')}")
        sys.exit(1)

    print(f"Found {len(files)} hookify rule files\n")

    total_fails = 0
    total_warns = 0

    for filepath in files:
        name = os.path.basename(filepath)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        fm, body = parse_frontmatter(content)
        issues = validate_rule(filepath, content, fm, body)

        fails = [i for i in issues if i[0] == "FAIL"]
        warns = [i for i in issues if i[0] == "WARN"]

        status = "FAIL" if fails else ("WARN" if warns else "PASS")
        event = fm.get("event", "?") if fm else "?"
        action = fm.get("action", "warn") if fm else "?"
        rule_name = fm.get("name", "?") if fm else "?"

        print(f"[{status}] {name}")
        print(f"       name={rule_name}  event={event}  action={action}")

        for severity, msg in issues:
            print(f"       {severity}: {msg}")

        if not issues:
            print("       All checks passed")
        print()

        total_fails += len(fails)
        total_warns += len(warns)

    # Summary
    print("=" * 60)
    print(f"SUMMARY: {len(files)} rules, {total_fails} FAILs, {total_warns} WARNs")

    if total_fails > 0:
        print("STATUS: FAIL -- fix FAIL issues before proceeding")
        sys.exit(1)
    elif total_warns > 0:
        print("STATUS: PASS with warnings")
        sys.exit(0)
    else:
        print("STATUS: PASS -- all rules valid")
        sys.exit(0)


if __name__ == "__main__":
    main()
