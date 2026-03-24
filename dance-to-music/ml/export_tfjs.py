"""
export_tfjs.py — Export trained Keras model to TensorFlow.js format.

The exported model can run in the browser via tf.loadLayersModel().

Usage:
  python export_tfjs.py                          # exports to ml/models/tfjs/
  python export_tfjs.py --model models/custom.h5 # export a specific model
"""

import os
import sys
import json
import shutil
from pathlib import Path

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

import tensorflow as tf


def export_to_tfjs(model_path, output_dir):
    """Export Keras .h5 model to TensorFlow.js layers format."""
    try:
        import tensorflowjs as tfjs
    except ImportError:
        print("ERROR: tensorflowjs not installed.")
        print("Install with: pip install tensorflowjs")
        sys.exit(1)

    model = tf.keras.models.load_model(
        str(model_path),
        custom_objects={"_combined_loss": _dummy_loss},
    )

    print(f"Model loaded: {model_path}")
    model.summary()

    # Export
    output_dir = Path(output_dir)
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)

    tfjs.converters.save_keras_model(model, str(output_dir))

    # Check output size
    total_size = sum(f.stat().st_size for f in output_dir.rglob("*") if f.is_file())
    print(f"\nExported to: {output_dir}")
    print(f"Total size: {total_size / 1024:.1f} KB")

    # List files
    for f in sorted(output_dir.rglob("*")):
        if f.is_file():
            print(f"  {f.name}: {f.stat().st_size / 1024:.1f} KB")

    # Copy model config alongside
    config_src = model_path.parent / "model_config.json"
    if config_src.exists():
        config_dst = output_dir / "model_config.json"
        shutil.copy2(config_src, config_dst)
        print(f"  Copied model_config.json")


def _dummy_loss(y_true, y_pred):
    """Placeholder for custom loss during model loading (not needed for inference)."""
    return tf.reduce_mean(tf.square(y_true - y_pred))


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

    output_dir = model_dir / "tfjs"
    export_to_tfjs(model_path, output_dir)
