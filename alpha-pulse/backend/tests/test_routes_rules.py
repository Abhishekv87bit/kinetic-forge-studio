async def test_seed_rules(client):
    resp = await client.post("/api/rules/seed")
    assert resp.status_code == 200
    data = resp.json()
    assert data["seeded"] == 8


async def test_list_rules(client):
    await client.post("/api/rules/seed")
    resp = await client.get("/api/rules")
    assert resp.status_code == 200
    rules = resp.json()
    assert len(rules) == 8


async def test_create_rule(client):
    resp = await client.post("/api/rules", json={
        "name": "Custom Rule",
        "rule_prompt": "Evaluate whether XYZ...",
        "weight": 0.7,
    })
    assert resp.status_code == 201
    assert resp.json()["name"] == "Custom Rule"
    assert resp.json()["active"] is True


async def test_get_rule(client):
    create_resp = await client.post("/api/rules", json={
        "name": "Test Rule",
        "rule_prompt": "Test prompt...",
        "weight": 0.5,
    })
    rule_id = create_resp.json()["id"]
    resp = await client.get(f"/api/rules/{rule_id}")
    assert resp.status_code == 200
    assert resp.json()["name"] == "Test Rule"


async def test_update_rule(client):
    create_resp = await client.post("/api/rules", json={
        "name": "Old Name",
        "rule_prompt": "Old prompt",
        "weight": 0.5,
    })
    rule_id = create_resp.json()["id"]
    resp = await client.patch(f"/api/rules/{rule_id}", json={
        "name": "New Name",
        "weight": 0.9,
    })
    assert resp.status_code == 200
    assert resp.json()["name"] == "New Name"
    assert resp.json()["weight"] == 0.9


async def test_toggle_rule_active(client):
    create_resp = await client.post("/api/rules", json={
        "name": "Toggle Test",
        "rule_prompt": "Prompt...",
    })
    rule_id = create_resp.json()["id"]
    resp = await client.patch(f"/api/rules/{rule_id}", json={"active": False})
    assert resp.status_code == 200
    assert resp.json()["active"] is False


async def test_seed_idempotent(client):
    """Calling seed twice should not create duplicate rules."""
    await client.post("/api/rules/seed")
    resp = await client.post("/api/rules/seed")
    assert resp.json()["seeded"] == 0
    assert resp.json()["skipped"] == 8
    # Total should still be 5
    list_resp = await client.get("/api/rules")
    assert len(list_resp.json()) == 8


async def test_update_rule_invalid_weight_rejected(client):
    """PATCH with weight > 1.0 should be rejected by Pydantic."""
    create_resp = await client.post("/api/rules", json={
        "name": "Weight Test",
        "rule_prompt": "Prompt...",
    })
    rule_id = create_resp.json()["id"]
    resp = await client.patch(f"/api/rules/{rule_id}", json={"weight": 5.0})
    assert resp.status_code == 422


async def test_delete_rule(client):
    create_resp = await client.post("/api/rules", json={
        "name": "To Delete",
        "rule_prompt": "Will be deleted",
    })
    rule_id = create_resp.json()["id"]
    resp = await client.delete(f"/api/rules/{rule_id}")
    assert resp.status_code == 200
    # Verify gone
    resp = await client.get(f"/api/rules/{rule_id}")
    assert resp.status_code == 404
