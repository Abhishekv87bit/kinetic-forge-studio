import pytest
from pathlib import Path
from app.models.profile import UserProfile

@pytest.fixture
def profile(tmp_path):
    return UserProfile(config_dir=tmp_path)

def test_default_profile(profile):
    data = profile.load()
    assert data["printer"]["tolerance"] == 0.2
    assert data["preferences"]["shaft_standard"] == 8

def test_update_profile(profile):
    profile.update({"printer": {"tolerance": 0.3}})
    data = profile.load()
    assert data["printer"]["tolerance"] == 0.3

def test_profile_persists(tmp_path):
    p1 = UserProfile(config_dir=tmp_path)
    p1.update({"preferences": {"default_material": "wood"}})
    p2 = UserProfile(config_dir=tmp_path)
    assert p2.load()["preferences"]["default_material"] == "wood"
