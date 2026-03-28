import argparse
import sys
from pathlib import Path

# Ensure project root is on sys.path so that `src.kfs_manifest` imports work
# when this script is run directly via `python src/kfs_manifest/cli.py`.
_project_root = str(Path(__file__).resolve().parent.parent.parent)
if _project_root not in sys.path:
    sys.path.insert(0, _project_root)

from src.kfs_manifest.parser import parse_kfs_manifest


class _KFSArgumentParser(argparse.ArgumentParser):
    """Custom ArgumentParser that formats missing-arg errors to include the argument name."""
    def error(self, message):
        # Include both usage and the error with argument name prefix
        self.print_usage(sys.stderr)
        # Reformat "the following arguments are required: manifest_file"
        # to "argument manifest_file: the following arguments are required: manifest_file"
        if "the following arguments are required:" in message:
            required_args = message.split("the following arguments are required: ")[-1]
            message = f"argument {required_args}: {message}"
        sys.stderr.write(f"{self.prog}: error: {message}\n")
        sys.exit(2)


def main():
    """Entry point for the KFS Manifest validation CLI."""
    parser = _KFSArgumentParser(
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
        print(f"\nValidation Failed: KFS Manifest '{manifest_path}' is invalid.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
