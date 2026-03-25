import argparse
import sys
from pathlib import Path

from src.kfs_manifest.parser import parse_kfs_manifest

def main():
    """Entry point for the KFS Manifest validation CLI."""
    parser = argparse.ArgumentParser(
        description="Validate a Kinetic Forge Studio (.kfs.yaml) manifest file."
    )
    parser.add_argument(
        "manifest_file",
        type=Path,
        help="Path to the .kfs.yaml manifest file."
    )
    args = parser.parse_args()

    manifest_path = args.manifest_file

    if not manifest_path.exists():
        print(f"Error: File not found at '{manifest_path}'", file=sys.stderr)
        sys.exit(1)
    if not manifest_path.is_file():
        print(f"Error: Path '{manifest_path}' is not a file.", file=sys.stderr)
        sys.exit(1)

    print(f"Attempting to validate KFS manifest: '{manifest_path}'")

    # The parse_kfs_manifest function handles loading, parsing, and printing errors.
    manifest = parse_kfs_manifest(manifest_path)

    if manifest:
        print(f"Success: KFS Manifest '{manifest_path}' is valid.")
        sys.exit(0)
    else:
        # parse_kfs_manifest already prints detailed errors to stderr
        print(f"\nValidation Failed: KFS Manifest '{manifest_path}' is invalid. See errors above.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
