import json, sys

d = json.load(sys.stdin)
summary = {k: v for k, v in d.items() if k != 'checks'}
print(json.dumps(summary, indent=2))

checks = d['checks']
print(f"\nTotal checks: {len(checks)}")

fails = [c for c in checks if c['status'] == 'FAIL']
warns = [c for c in checks if c['status'] == 'WARN']
infos = [c for c in checks if c['status'] == 'INFO']
passes = [c for c in checks if c['status'] == 'PASS']

print(f"PASS: {len(passes)}, FAIL: {len(fails)}, WARN: {len(warns)}, INFO: {len(infos)}")

if fails:
    print("\n--- FAILURES ---")
    for c in fails:
        print(f"  FAIL | {json.dumps(c)}")

if warns:
    print("\n--- WARNINGS ---")
    for c in warns:
        print(f"  WARN | {json.dumps(c)}")

if infos:
    print("\n--- INFO ---")
    for c in infos[:15]:
        print(f"  INFO | {json.dumps(c)}")
    if len(infos) > 15:
        print(f"  ... and {len(infos) - 15} more INFO checks")
