import click
import yaml
import json
from pathlib import Path

from backend.kfs_manifest.schema.v1.kinetic_forge_schema import KineticForgeManifest


@click.group()
def cli():
    """KFS Manifest CLI - Tools for working with KFS manifest files."""
    pass


@cli.command()
@click.argument("manifest_path", type=click.Path(exists=False))
def validate(manifest_path: str):
    """Validate a KFS manifest file."""
    path = Path(manifest_path)

    if not path.exists():
        click.echo(f"Error: File not found: {path}")
        raise SystemExit(1)

    try:
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        click.echo(f"Error: Failed to parse manifest file: {type(e).__name__}: {e}")
        raise SystemExit(1)

    if not isinstance(data, dict):
        click.echo("Error: Manifest file content is not a valid dictionary.")
        raise SystemExit(1)

    # Check version
    kfs_version = data.get("kfs_version")
    if not kfs_version:
        click.echo("Manifest validation failed.")
        click.echo("field required: kfs_version")
        raise SystemExit(1)

    # Simple version check
    supported_versions = {"1.0.0"}
    if kfs_version not in supported_versions:
        click.echo("Manifest validation failed.")
        click.echo(f"Unsupported KFS version: {kfs_version}")
        raise SystemExit(1)

    click.echo("Manifest is valid.")


@cli.command("generate-schema")
@click.option("--output", "-o", type=click.Path(), required=True, help="Output path for the JSON schema.")
def generate_schema(output: str):
    """Generate the KFS Manifest JSON schema."""
    schema = KineticForgeManifest.model_json_schema()
    schema["$schema"] = "http://json-schema.org/draft-07/schema#"
    schema["$id"] = "https://kineticforgestudio.com/schemas/kfs-manifest-v1.json"
    schema.setdefault("title", "KFS Manifest Schema")
    schema.setdefault("description", "Schema for Kinetic Forge Studio manifest files.")

    output_path = Path(output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(schema, f, indent=2)

    click.echo(f"KFS Manifest JSON schema generated successfully at {output_path}")


if __name__ == "__main__":
    cli()
