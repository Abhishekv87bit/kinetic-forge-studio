"""
export_onnx.py — Export trained Keras model to ONNX format for browser inference.

ONNX Runtime Web runs in the browser via WebAssembly/WebGL.
This avoids TensorFlow.js dependency chain issues.

Usage:
  python export_onnx.py                          # exports to ml/models/
  python export_onnx.py --model models/custom.h5 # export a specific model
"""

import os
import sys
import json
import shutil
from pathlib import Path

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"


def export_to_onnx(model_path, output_path):
    """Export Keras .h5 model to ONNX format."""
    # Import tensorflow with suppressed warnings
    import tensorflow as tf
    from tensorflow import keras

    # Load model
    model = keras.models.load_model(str(model_path), compile=False)
    print(f"Model loaded: {model_path}")
    model.summary()

    # Save as SavedModel first (tf2onnx needs this)
    saved_model_dir = model_path.parent / "_saved_model_tmp"
    model.save(str(saved_model_dir))
    print(f"Saved as SavedModel: {saved_model_dir}")

    # Convert to ONNX
    import subprocess
    result = subprocess.run(
        [
            sys.executable, "-m", "tf2onnx.convert",
            "--saved-model", str(saved_model_dir),
            "--output", str(output_path),
            "--opset", "13",
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print(f"ONNX conversion error:\n{result.stderr}")
        sys.exit(1)

    # Cleanup temp saved model
    shutil.rmtree(saved_model_dir, ignore_errors=True)

    # Check output
    file_size = output_path.stat().st_size
    print(f"\nExported to: {output_path}")
    print(f"ONNX model size: {file_size / 1024:.1f} KB")

    # Verify ONNX model
    import onnxruntime as ort
    import numpy as np

    sess = ort.InferenceSession(str(output_path))
    input_info = sess.get_inputs()
    output_info = sess.get_outputs()

    print(f"\nONNX model inputs:")
    for inp in input_info:
        print(f"  {inp.name}: shape={inp.shape}, type={inp.type}")

    print(f"ONNX model outputs:")
    for out in output_info:
        print(f"  {out.name}: shape={out.shape}, type={out.type}")

    # Test inference
    test_input = np.random.randn(1, 32, 7).astype(np.float32)
    result = sess.run(None, {input_info[0].name: test_input})
    print(f"\nTest inference: input shape {test_input.shape} → output shape {result[0].shape}")
    print(f"Output values: {result[0][0]}")
    print("ONNX export PASS")


if __name__ == "__main__":
    model_dir = Path(__file__).parent / "models"

    if "--model" in sys.argv:
        idx = sys.argv.index("--model")
        model_path = Path(sys.argv[idx + 1])
    else:
        model_path = model_dir / "motion_to_music.h5"

    if not model_path.exists():
        print(f"Model not found: {model_path}")
        print("Train first with: python train_model.py --synthetic")
        sys.exit(1)

    output_path = model_dir / "motion_to_music.onnx"
    export_to_onnx(model_path, output_path)
