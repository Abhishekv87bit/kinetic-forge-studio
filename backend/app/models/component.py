import json
from app.db.database import Database

class ComponentManager:
    def __init__(self, db: Database):
        self.db = db

    async def register(self, project_id: str, component_id: str, display_name: str,
                       component_type: str, parameters: dict, position: dict = None,
                       decided_by: list[int] = None) -> dict:
        existing = await self.db.conn.execute(
            "SELECT id FROM components WHERE id = ? AND project_id = ?",
            (component_id, project_id))
        if await existing.fetchone():
            raise ValueError(f"Component '{component_id}' already exists in this project")

        await self.db.conn.execute(
            """INSERT INTO components (id, project_id, display_name, component_type,
               parameters, position, decided_by) VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (component_id, project_id, display_name, component_type,
             json.dumps(parameters), json.dumps(position or {}),
             json.dumps(decided_by or []))
        )
        await self.db.conn.commit()
        return {"id": component_id, "display_name": display_name,
                "type": component_type, "parameters": parameters}

    async def get(self, project_id: str, component_id: str) -> dict:
        cursor = await self.db.conn.execute(
            "SELECT * FROM components WHERE id = ? AND project_id = ?",
            (component_id, project_id))
        row = await cursor.fetchone()
        if not row:
            raise ValueError(f"Component '{component_id}' not found")
        return {"id": row["id"], "display_name": row["display_name"],
                "type": row["component_type"],
                "parameters": json.loads(row["parameters"]),
                "position": json.loads(row["position"]),
                "decided_by": json.loads(row["decided_by"])}

    async def list_all(self, project_id: str) -> list[dict]:
        cursor = await self.db.conn.execute(
            "SELECT * FROM components WHERE project_id = ? ORDER BY created_at", (project_id,))
        rows = await cursor.fetchall()
        return [{"id": r["id"], "display_name": r["display_name"],
                 "type": r["component_type"],
                 "parameters": json.loads(r["parameters"]),
                 "position": json.loads(r["position"])}
                for r in rows]

    async def update_params(self, project_id: str, component_id: str, params: dict):
        current = await self.get(project_id, component_id)
        merged = {**current["parameters"], **params}
        await self.db.conn.execute(
            "UPDATE components SET parameters = ? WHERE id = ? AND project_id = ?",
            (json.dumps(merged), component_id, project_id))
        await self.db.conn.commit()

    async def as_context(self, project_id: str) -> dict:
        components = await self.list_all(project_id)
        return {c["id"]: c for c in components}
