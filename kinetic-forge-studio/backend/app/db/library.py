"""
Reference library with SQLite full-text search.

Provides indexed storage and search for mechanisms, components,
and design patterns. Uses SQLite FTS5 for fast keyword matching
across mechanism types, keywords, and names.
"""

import uuid
from typing import Any

from app.db.database import Database


class LibraryManager:
    """
    Manage the reference library with full-text search capabilities.

    Entries represent reusable mechanisms, components, or design patterns
    that can be searched by name, mechanism type, keywords, or dimensions.
    """

    def __init__(self, db: Database):
        self.db = db

    async def _ensure_fts(self):
        """Create FTS5 virtual table if it doesn't exist."""
        await self.db.conn.executescript("""
            CREATE VIRTUAL TABLE IF NOT EXISTS library_fts USING fts5(
                id UNINDEXED,
                name,
                mechanism_types,
                keywords,
                content='library',
                content_rowid='rowid'
            );
        """)
        await self.db.conn.commit()

    async def add(
        self,
        name: str,
        mechanism_types: str = "",
        keywords: str = "",
        source: str = "",
        envelope_x: float | None = None,
        envelope_y: float | None = None,
        envelope_z: float | None = None,
        file_path: str = "",
        thumbnail_path: str = "",
        project_id: str | None = None,
    ) -> dict[str, Any]:
        """
        Add a new entry to the reference library.

        Args:
            name: Display name of the entry.
            mechanism_types: Comma-separated mechanism types (e.g., "four-bar,cam-follower").
            keywords: Comma-separated keywords for search (e.g., "oscillating,smooth,brass").
            source: Origin of the entry (e.g., "user", "import", "generated").
            envelope_x: Bounding envelope X dimension in mm.
            envelope_y: Bounding envelope Y dimension in mm.
            envelope_z: Bounding envelope Z dimension in mm.
            file_path: Path to associated geometry file.
            thumbnail_path: Path to thumbnail image.
            project_id: Associated project ID (optional).

        Returns:
            Dict with the created entry data including generated ID.
        """
        await self._ensure_fts()

        entry_id = uuid.uuid4().hex[:12]
        await self.db.conn.execute(
            """INSERT INTO library (id, name, source, mechanism_types, keywords,
               envelope_x, envelope_y, envelope_z, file_path, thumbnail_path, project_id)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (entry_id, name, source, mechanism_types, keywords,
             envelope_x, envelope_y, envelope_z, file_path, thumbnail_path, project_id),
        )

        # Update FTS index
        cursor = await self.db.conn.execute(
            "SELECT rowid FROM library WHERE id = ?", (entry_id,)
        )
        row = await cursor.fetchone()
        if row:
            await self.db.conn.execute(
                "INSERT INTO library_fts(rowid, id, name, mechanism_types, keywords) VALUES (?, ?, ?, ?, ?)",
                (row["rowid"], entry_id, name, mechanism_types, keywords),
            )

        await self.db.conn.commit()

        return {
            "id": entry_id,
            "name": name,
            "mechanism_types": mechanism_types,
            "keywords": keywords,
            "source": source,
            "envelope_x": envelope_x,
            "envelope_y": envelope_y,
            "envelope_z": envelope_z,
            "file_path": file_path,
            "thumbnail_path": thumbnail_path,
            "project_id": project_id,
        }

    async def get(self, entry_id: str) -> dict[str, Any]:
        """
        Get a library entry by ID.

        Raises:
            ValueError: If entry not found.
        """
        cursor = await self.db.conn.execute(
            "SELECT * FROM library WHERE id = ?", (entry_id,)
        )
        row = await cursor.fetchone()
        if not row:
            raise ValueError(f"Library entry '{entry_id}' not found")

        return self._row_to_dict(row)

    async def search(self, query: str) -> list[dict[str, Any]]:
        """
        Search the library using full-text search.

        Searches across name, mechanism_types, and keywords fields.
        Uses SQLite FTS5 match syntax. Simple terms are auto-wrapped
        with wildcards for prefix matching.

        Args:
            query: Search query string (e.g., "four-bar", "oscillating gear").

        Returns:
            List of matching entries, ranked by relevance.
        """
        await self._ensure_fts()

        if not query or not query.strip():
            # Return all entries if query is empty
            cursor = await self.db.conn.execute(
                "SELECT * FROM library ORDER BY created_at DESC"
            )
            rows = await cursor.fetchall()
            return [self._row_to_dict(r) for r in rows]

        # Prepare FTS query: add * for prefix matching to each term
        terms = query.strip().split()
        fts_query = " OR ".join(f'"{t}"*' for t in terms)

        try:
            cursor = await self.db.conn.execute(
                """SELECT library.* FROM library
                   JOIN library_fts ON library.id = library_fts.id
                   WHERE library_fts MATCH ?
                   ORDER BY rank""",
                (fts_query,),
            )
            rows = await cursor.fetchall()
            return [self._row_to_dict(r) for r in rows]
        except Exception:
            # Fallback to LIKE search if FTS query fails
            like_pattern = f"%{query}%"
            cursor = await self.db.conn.execute(
                """SELECT * FROM library
                   WHERE name LIKE ? OR mechanism_types LIKE ? OR keywords LIKE ?
                   ORDER BY created_at DESC""",
                (like_pattern, like_pattern, like_pattern),
            )
            rows = await cursor.fetchall()
            return [self._row_to_dict(r) for r in rows]

    async def list_all(self) -> list[dict[str, Any]]:
        """List all library entries."""
        cursor = await self.db.conn.execute(
            "SELECT * FROM library ORDER BY created_at DESC"
        )
        rows = await cursor.fetchall()
        return [self._row_to_dict(r) for r in rows]

    async def delete(self, entry_id: str) -> bool:
        """Delete a library entry by ID. Returns True if deleted."""
        cursor = await self.db.conn.execute(
            "DELETE FROM library WHERE id = ?", (entry_id,)
        )
        await self.db.conn.commit()
        return cursor.rowcount > 0

    def _row_to_dict(self, row) -> dict[str, Any]:
        """Convert a database row to a dict."""
        return {
            "id": row["id"],
            "name": row["name"],
            "mechanism_types": row["mechanism_types"] or "",
            "keywords": row["keywords"] or "",
            "source": row["source"] or "",
            "envelope_x": row["envelope_x"],
            "envelope_y": row["envelope_y"],
            "envelope_z": row["envelope_z"],
            "file_path": row["file_path"] or "",
            "thumbnail_path": row["thumbnail_path"] or "",
            "project_id": row["project_id"],
            "created_at": row["created_at"],
        }
