import json
from pathlib import Path
from copy import deepcopy

DEFAULT_PROFILE = {
    "printer": {
        "type": "FDM",
        "nozzle": 0.4,
        "layer_height": 0.2,
        "tolerance": 0.2,
        "min_wall": 1.5,
        "max_overhang": 45
    },
    "preferences": {
        "default_material": "PLA",
        "default_module": 1.5,
        "preferred_mechanisms": ["four_bar", "planetary", "scotch_yoke"],
        "shaft_standard": 8
    },
    "style_tags": ["organic", "wave", "museum_quality"],
    "production_target": "metal_and_wood"
}

class UserProfile:
    def __init__(self, config_dir: Path):
        self.path = config_dir / "profile.json"
        if not self.path.exists():
            self.path.parent.mkdir(parents=True, exist_ok=True)
            self._save(DEFAULT_PROFILE)

    def load(self) -> dict:
        return json.loads(self.path.read_text())

    def update(self, updates: dict):
        data = self.load()
        self._deep_merge(data, updates)
        self._save(data)

    def _save(self, data: dict):
        self.path.write_text(json.dumps(data, indent=2))

    def _deep_merge(self, base: dict, updates: dict):
        for key, value in updates.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._deep_merge(base[key], value)
            else:
                base[key] = value
