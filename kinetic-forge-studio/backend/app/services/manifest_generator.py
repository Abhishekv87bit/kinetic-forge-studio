import json
from datetime import datetime, timezone
from pathlib import Path

from app.config import settings
from app.db.database import Database


async def generate_manifest(project_id: str, db: Database) -> dict:
    cursor = await db.conn.execute(
        "SELECT name FROM projects WHERE id = ?", (project_id,)
    )
    row = await cursor.fetchone()
    project_name = row["name"] if row else project_id

    cursor = await db.conn.execute(
        """SELECT id, name, version, language, status
           FROM modules WHERE project_id = ?
           ORDER BY created_at ASC""",
        (project_id,),
    )
    module_rows = await cursor.fetchall()

    modules = []
    for m in module_rows:
        module_id = m["id"]
        cursor2 = await db.conn.execute(
            """SELECT tier, passed FROM vlad_results
               WHERE module_id = ?
               ORDER BY created_at DESC LIMIT 1""",
            (module_id,),
        )
        vlad_row = await cursor2.fetchone()
        vlad_status = None
        if vlad_row:
            vlad_status = "passed" if vlad_row["passed"] else "failed"

        modules.append({
            "name": m["name"],
            "version": m["version"],
            "language": m["language"],
            "status": m["status"],
            "vlad": vlad_status,
        })

    passed = sum(1 for m in modules if m["vlad"] == "passed")
    failed = sum(1 for m in modules if m["vlad"] == "failed")
    unvalidated = sum(1 for m in modules if m["vlad"] is None)

    return {
        "project_name": project_name,
        "project_id": project_id,
        "modules": modules,
        "vlad_summary": {
            "passed": passed,
            "failed": failed,
            "unvalidated": unvalidated,
            "total": len(modules),
        },
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
