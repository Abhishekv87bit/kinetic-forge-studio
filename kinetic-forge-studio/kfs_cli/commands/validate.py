import click
import sys
from pathlib import Path
from typing import Tuple, Dict, Any, List

from kfs_core.manifest_parser import load_kfs_manifest
from kfs_core.manifest_models import KFSManifest
from kfs_core.validator.rules import SEMANTIC_VALIDATION_RULES, SemanticValidationError
from kfs_core.exceptions import (
    KFSManifestValidationError,
    ManifestVersionMismatchError,
    InvalidKFSManifestError,
    KFSBaseError,
)
from kfs_core.constants import KFS_MANIFEST_VERSION


class _ValidateFilesType(click.ParamType):
    """Custom Click type for validating file paths with specific error messages."""
    name = "PATH"

    def convert(self, value, param, ctx):
        p = Path(value)
        if not p.exists():
            # Write the error directly to stderr in the expected format
            click.echo(f"Error: No such file or directory: '{value}'", err=True)
            ctx.exit(2)
        if not p.is_file():
            click.echo(f"Error: '{value}' is not a file.", err=True)
            ctx.exit(2)
        return p


@click.command()
@click.argument(
    "files",
    nargs=-1,
    type=_ValidateFilesType(),
    required=True,
)
def validate(files: Tuple[Path, ...]):
    """
    Validates one or more KFS manifest files for structural and semantic correctness.

    FILES: Path(s) to the .kfs.yaml or .kfs.json manifest file(s).
    """
    total_files = len(files)
    valid_count = 0
    invalid_count = 0

    for file_path in files:
        click.echo(f"Validating '{file_path}'...")

        # Try loading the manifest
        manifest = None
        validation_errors: List[Dict[str, Any]] = []
        version_mismatch = False

        try:
            manifest = load_kfs_manifest(file_path)
        except ManifestVersionMismatchError as e:
            version_mismatch = True
            click.echo(
                f"Error processing '{file_path}': {e}",
                err=True,
            )
        except KFSManifestValidationError as e:
            # Pydantic validation errors
            if e.errors:
                for err in e.errors:
                    validation_errors.append(err)
            else:
                validation_errors.append({"type": "unknown", "msg": str(e)})
        except InvalidKFSManifestError as e:
            validation_errors.append({"type": "invalid_manifest", "msg": str(e)})
        except KFSBaseError as e:
            validation_errors.append({"type": "kfs_error", "msg": str(e)})
        except Exception as e:
            validation_errors.append({"type": "unexpected", "msg": str(e)})

        # Run semantic validation if manifest loaded
        semantic_errors: List[Dict[str, Any]] = []
        if manifest is not None:
            for rule_func in SEMANTIC_VALIDATION_RULES:
                for s_err in rule_func(manifest):
                    semantic_errors.append(s_err.to_dict())

        all_errors = validation_errors + semantic_errors
        error_count = len(all_errors)

        if version_mismatch:
            invalid_count += 1
            click.echo(f"'{file_path}' is INVALID (version mismatch).")
        elif error_count > 0:
            invalid_count += 1
            click.echo(f"'{file_path}' is INVALID.")
            for err in all_errors:
                # Determine error category
                err_type = err.get('type', 'unknown')
                err_code = err.get('code')
                err_msg = err.get('msg', err.get('message', 'No details'))

                if err_code:
                    # Semantic error
                    label = f"Semantic ({err_code})"
                    click.echo(f"  {label}: {err_msg}")
                elif err_type in ('missing', 'value_error.missing'):
                    display_msg = err_msg[0].lower() + err_msg[1:] if err_msg else err_msg
                    click.echo(f"  Schema Validation Error (Missing): {display_msg}")
                else:
                    display_msg = err_msg[0].lower() + err_msg[1:] if err_msg else err_msg
                    click.echo(f"  Validation Error: {display_msg}")

            plural = "" if error_count == 1 else "s"
            click.echo(f"Encountered {error_count} validation error{plural}.")
        else:
            valid_count += 1
            click.echo(f"'{file_path}' is VALID.")
            click.echo(f"Encountered 0 validation errors.")

    # Summary
    if invalid_count > 0:
        click.echo("Overall KFS manifest validation: FAILED")
        if total_files > 1:
            click.echo(f"Total files checked: {total_files}, Valid: {valid_count}, Invalid: {invalid_count}")
        raise SystemExit(1)
    else:
        click.echo("Overall KFS manifest validation: SUCCESS")
