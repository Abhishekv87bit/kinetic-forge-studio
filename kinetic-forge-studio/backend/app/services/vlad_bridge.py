import json

from app.services.vlad_runner import VladResult


def parse_vlad_output(raw_json: str) -> VladResult:
    try:
        data = json.loads(raw_json)
    except json.JSONDecodeError:
        findings = [line.strip() for line in raw_json.splitlines() if line.strip()]
        passed = not any(
            kw in raw_json.upper() for kw in ("FAIL", "ERROR", "EXCEPTION")
        )
        return VladResult(passed=passed, findings=findings)

    return VladResult(
        tier=str(data.get("tier", "")),
        passed=bool(data.get("passed", False)),
        checks_run=list(data.get("checks_run", [])),
        checks_passed=list(data.get("checks_passed", [])),
        checks_failed=list(data.get("checks_failed", [])),
        findings=list(data.get("findings", data.get("errors", []))),
    )
