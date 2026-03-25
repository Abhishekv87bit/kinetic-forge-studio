import click
import yaml
from pathlib import Path
from pydantic import ValidationError as PydanticValidationError

from kfs_core.manifest_models import KFSManifest
from kfs_core.constants import KFS_MANIFEST_VERSION, KFS_DEFAULT_MANIFEST_FILENAME

@click.command()
@click.argument("filename", type=click.Path(path_type=Path), default=KFS_DEFAULT_MANIFEST_FILENAME, required=False)
@click.option(
    "--overwrite",
    "-o",
    is_flag=True,
    default=False,
    help="Overwrite the file if it already exists.",
)
def generate(filename: Path, overwrite: bool):
    """
    Generates a blank KFS manifest file template.

    FILENAME: The name of the manifest file to create (e.g., kfs.yaml).
              Defaults to 'kfs.yaml'.
    """
    if filename.exists() and not overwrite:
        click.echo(f"Error: File '{filename}' already exists. Use --overwrite to force overwrite.", err=True)
        return

    project_name_stem = filename.stem.replace('-', ' ').replace('_', ' ').title()
    if project_name_stem.lower() == "kfs":
        project_name = "Untitled Kinetic Sculpture"
    else:
        project_name = project_name_stem

    # Create a minimal KFSManifest object's data as a dictionary.
    # This structure aligns with the required fields and optional sections
    # that should be present for a user to fill out.
    template_data = {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": project_name,
        "description": None, # Explicitly include null for clarity in template
        "geometries": {},
        "materials": {},
        "objects": [], # Required field, initialize as empty list
        "simulation_settings": {} # Explicitly include empty dict for clarity in template
    }

    try:
        # Validate the template_data against the Pydantic model to ensure it's a valid starting point.
        # This catches any errors in our template generation logic itself.
        KFSManifest(**template_data)

        with open(filename, "w", encoding="utf-8") as f:
            # Use yaml.dump with specific settings for good readability (block style, custom order)
            yaml.dump(template_data, f, indent=2, sort_keys=False, default_flow_style=False)

        click.echo(f"Successfully generated blank KFS manifest to '{filename}'")
    except PydanticValidationError as e:
        click.echo(f"Internal Error: Generated template data is invalid according to KFSManifest schema.", err=True)
        for error in e.errors():
            loc = "/".join(map(str, error['loc']))
            click.echo(f"  - Path: {loc}, Message: {error['msg']}", err=True)
        click.echo("Please report this issue.", err=True)
    except Exception as e:
        click.echo(f"An unexpected error occurred: {e}", err=True)