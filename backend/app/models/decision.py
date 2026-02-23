from app.db.database import Database

class DecisionManager:
    def __init__(self, db: Database):
        self.db = db

    async def add(self, project_id: str, parameter: str, value: str,
                  reason: str = "", source: str = "user", session_id: str = None) -> dict:
        cursor = await self.db.conn.execute(
            """INSERT INTO decisions (project_id, parameter, value, reason, source, session_id, status)
               VALUES (?, ?, ?, ?, ?, ?, 'proposed')""",
            (project_id, parameter, value, reason, source, session_id)
        )
        await self.db.conn.commit()
        return {"id": cursor.lastrowid, "parameter": parameter, "value": value,
                "reason": reason, "source": source, "status": "proposed"}

    async def lock(self, project_id: str, decision_id: int) -> dict:
        await self.db.conn.execute(
            "UPDATE decisions SET status = 'locked' WHERE id = ? AND project_id = ?",
            (decision_id, project_id)
        )
        await self.db.conn.commit()
        cursor = await self.db.conn.execute("SELECT * FROM decisions WHERE id = ?", (decision_id,))
        row = await cursor.fetchone()
        return dict(row)

    async def check_conflicts(self, project_id: str, parameter: str, value: str) -> list[dict]:
        cursor = await self.db.conn.execute(
            """SELECT * FROM decisions
               WHERE project_id = ? AND parameter = ? AND status = 'locked' AND value != ?""",
            (project_id, parameter, value)
        )
        rows = await cursor.fetchall()
        return [dict(r) for r in rows]

    async def supersede(self, project_id: str, old_id: int, new_value: str, reason: str = "") -> dict:
        cursor = await self.db.conn.execute("SELECT * FROM decisions WHERE id = ?", (old_id,))
        old = await cursor.fetchone()
        new = await self.add(project_id, parameter=old["parameter"], value=new_value,
                             reason=reason, source="user")
        await self.db.conn.execute(
            "UPDATE decisions SET status = 'superseded', superseded_by = ? WHERE id = ?",
            (new["id"], old_id)
        )
        await self.db.conn.commit()
        return new

    async def list_all(self, project_id: str) -> list[dict]:
        cursor = await self.db.conn.execute(
            "SELECT * FROM decisions WHERE project_id = ? ORDER BY id", (project_id,))
        return [dict(r) for r in await cursor.fetchall()]

    async def list_locked(self, project_id: str) -> list[dict]:
        cursor = await self.db.conn.execute(
            "SELECT * FROM decisions WHERE project_id = ? AND status = 'locked' ORDER BY id",
            (project_id,))
        return [dict(r) for r in await cursor.fetchall()]
