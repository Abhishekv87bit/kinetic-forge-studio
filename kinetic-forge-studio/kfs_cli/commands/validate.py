import click
from pathlib import Path
from typing import Tuple, Dict, Any

from kfs_core.validator.manifest_validator import KFSManifestValidator
from kfs_core.exceptions import (
    KFSManifestValidationError,
    ManifestVersionMismatchError,
    InvalidKFSManifestError,
    KFSBaseError
)

def _format_error_path(error_dict: Dict[str, Any]) -> str:
    """Formats the error path from either a Pydantic 'loc' or a custom 'path'."""
    if 'path' in error_dict: # Semantic error path (already string)
        return error_dict['path']
    elif 'loc' in error_dict: # Pydantic error location (tuple)
        # Convert tuple like ('objects', 0, 'id') to 'objects/0/id'
        return "/".join(map(str, error_dict['loc']))
    return "N/A"

def _format_error_message(error_dict: Dict[str, Any]) -> str:
    """Formats the error message from a Pydantic 'msg' or a custom 'message'."""
    if 'message' in error_dict: # Semantic error message
        return error_dict['message']
    elif 'msg' in error_dict: # Pydantic error message
        return error_dict['msg']
    return "No message"

def _format_error_type_code(error_dict: Dict[str, Any]) -> str:
    """Determines error type and code for display."""
    error_type = error_dict.get('type', 'Unknown').replace('_', ' ').title()
    error_code = error_dict.get('code') # Semantic errors have 'code'

    if error_code:
        return f"{error_type} ({error_code})"
    return error_type


@click.command()
@click.argument(
    "files",
    nargs=-1,
    type=click.Path(exists=True, file_okay=True, dir_okay=False, readable=True, path_type=Path),
    required=True
)
def validate(files: Tuple[Path, ...]):
    """
    Validates one or more KFS manifest files for structural and semantic correctness.

    FILES: Path(s) to the .kfs.yaml or .kfs.json manifest file(s).
    """
    validator = KFSManifestValidator()
    all_valid = True

    for file_path in files:
        click.echo(f"Validating '{file_path}'...")
        try:
            manifest = validator.validate_manifest(file_path)
            click.echo(click.style(f"  '{file_path}' is VALID. (Name: {manifest.name})", fg="green"))
        except ManifestVersionMismatchError as e:
            all_valid = False
            click.echo(click.style(f"  Error validating '{file_path}': Manifest Version Mismatch.", fg="red"))
            click.echo(click.style(f"    Details: {e}", fg="red"))
        except InvalidKFSManifestError as e:
            all_valid = False
            click.echo(click.style(f"  Error validating '{file_path}': Invalid Manifest Structure (YAML/JSON parsing or basic structure).", fg="red"))
            click.echo(click.style(f"    Details: {e}", fg="red"))
        except KFSManifestValidationError as e:
            all_valid = False
            click.echo(click.style(f"  Error validating '{file_path}': KFS Manifest Validation Failed.", fg="red"))
            if e.errors:
                for err in e.errors:
                    formatted_type_code = _format_error_type_code(err)
                    formatted_message = _format_error_message(err)
                    formatted_path = _format_error_path(err)
                    
                    # 'value' field is generally more present in semantic errors.
                    # Pydantic errors might not have a direct 'value' in the error dict.
                    err_value = err.get('value')
                    
                    click.echo(click.style(f"    [{formatted_type_code}]: {formatted_message}", fg="red"))
                    if formatted_path and formatted_path != 'N/A':
                        click.echo(click.style(f"      Path: {formatted_path}", fg="red"))
                    if err_value is not None:
                        # Truncate long values for cleaner output
                        display_value = str(err_value)
                        if len(display_value) > 100:
                            display_value = display_value[:97] + "..."
                        click.echo(click.style(f"      Value: {display_value}", fg="red"))
            else:
                click.echo(click.style(f"    Details: {e}", fg="red")) # Fallback if errors list is empty
        except KFSBaseError as e:
            all_valid = False
            click.echo(click.style(f"  An unexpected KFS error occurred for '{file_path}': {e}", fg="red"))
        except Exception as e:
            all_valid = False
            click.echo(click.style(f"  An unhandled error occurred for '{file_path}': {e}", fg="red"))
        click.echo("-" * 40)

    if not all_valid:
        click.echo(click.style("One or more manifests failed validation.", fg="red"))
        raise click.exceptions.Exit(1)
    else:
        click.echo(click.style("All specified manifests passed validation.", fg="green"))
