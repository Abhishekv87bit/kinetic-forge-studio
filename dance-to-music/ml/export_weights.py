"""
export_weights.py — Export model weights as JSON for manual JS inference.

Supports both V1 (sequential) and V2 (functional with decomposed heads) models.
Since models are small (~35K params), we implement forward pass in pure JavaScript
without any ML framework. This avoids TF.js/ONNX dependency issues.

Usage:
  python export_weights.py           # export V2 model
  python export_weights.py --v1      # export V1 model
"""

import os
import sys
import json
from pathlib import Path

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"

MODEL_DIR = Path(__file__).parent / "models"


def export_weights(model_name="motion_to_music_v2"):
    """Extract weights from .h5 file and save as JSON + binary."""
    import h5py
    import numpy as np

    h5_path = MODEL_DIR / f"{model_name}.h5"
    if not h5_path.exists():
        print(f"Model not found: {h5_path}")
        print("Train first with: python train_model.py --synthetic")
        sys.exit(1)

    suffix = "_v2" if "v2" in model_name else ""
    print(f"Loading weights from {h5_path}")

    with h5py.File(str(h5_path), "r") as f:
        # Print structure
        def print_structure(name, obj):
            if isinstance(obj, h5py.Dataset):
                print(f"  {name}: shape={obj.shape}, dtype={obj.dtype}")

        print("H5 structure:")
        f.visititems(print_structure)

        # Extract all weight arrays
        weights = {}

        def extract_weights(name, obj):
            if isinstance(obj, h5py.Dataset):
                # Skip optimizer weights
                if "optimizer" in name:
                    return
                arr = np.array(obj)
                # Clean up the name for JS
                clean_name = name.replace("/", "__")
                weights[clean_name] = arr

        f.visititems(extract_weights)

    # Save outputs
    output_dir = MODEL_DIR
    output_dir.mkdir(parents=True, exist_ok=True)

    # Convert numpy arrays to lists for JSON serialization
    json_weights = {}
    total_params = 0
    for name, arr in weights.items():
        json_weights[name] = {
            "shape": list(arr.shape),
            "data": arr.flatten().tolist(),
        }
        total_params += arr.size
        print(f"  {name}: shape={arr.shape}, params={arr.size}")

    print(f"\nTotal parameters: {total_params}")

    # Save JSON weights
    json_path = output_dir / f"model_weights{suffix}.json"
    with open(json_path, "w") as f:
        json.dump(json_weights, f)
    json_size = json_path.stat().st_size
    print(f"JSON weights: {json_path} ({json_size / 1024:.1f} KB)")

    # Save as compact binary (float32) for faster loading
    bin_path = output_dir / f"model_weights{suffix}.bin"
    manifest = {}
    offset = 0

    with open(bin_path, "wb") as f:
        for name, arr in weights.items():
            flat = arr.flatten().astype(np.float32)
            f.write(flat.tobytes())
            manifest[name] = {
                "shape": list(arr.shape),
                "offset": offset,
                "length": flat.size,
            }
            offset += flat.size * 4

    bin_size = bin_path.stat().st_size
    print(f"Binary weights: {bin_path} ({bin_size / 1024:.1f} KB)")

    # Save manifest
    manifest_path = output_dir / f"model_manifest{suffix}.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"Manifest: {manifest_path}")

    # Copy config alongside weights
    config_path = MODEL_DIR / f"model_config{suffix}.json"
    if config_path.exists():
        print(f"Config: {config_path}")

    print(f"\nExport complete ({total_params} params, {bin_size / 1024:.1f} KB binary)")


if __name__ == "__main__":
    if "--v1" in sys.argv:
        export_weights("motion_to_music")
    else:
        export_weights("motion_to_music_v2")
