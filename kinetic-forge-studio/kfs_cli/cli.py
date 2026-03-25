import click
import sys
from pathlib import Path
from kfs_core.io import load_kfs_manifest
from pydantic import ValidationError
import yaml # for yaml.YAMLError

@click.group()
def cli():
    """Kinetic Forge Studio (KFS) Manifest CLI."""
    pass

@cli.command()
@click.argument('manifest_file', type=click.Path(exists=True, dir_okay=False, readable=True))
def validate(manifest_file):
    """
    Validates a KFS manifest file.
    """
    try:
        load_kfs_manifest(manifest_file)
        click.echo(f"Manifest '{manifest_file}' is VALID.")
        sys.exit(0)
    except FileNotFoundError as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
    except (yaml.YAMLError, ValidationError, ValueError) as e:
        click.echo(f"Manifest '{manifest_file}' is INVALID: {e}", err=True)
        sys.exit(1)
    except Exception as e:
        click.echo(f"An unexpected error occurred: {e}", err=True)
        sys.exit(1)

@cli.command()
@click.argument('manifest_file', type=click.Path(exists=True, dir_okay=False, readable=True))
def display(manifest_file):
    """
    Displays summary information about a KFS manifest file.
    """
    try:
        manifest = load_kfs_manifest(manifest_file)
        click.echo(f"--- KFS Manifest Summary ---")
        click.echo(f"Project Name: {manifest.project_name}")
        click.echo(f"Version: {manifest.version}")
        click.echo(f"Description: {manifest.description or 'N/A'}")
        click.echo(f"Number of Materials: {len(manifest.materials)}")
        click.echo(f"Number of Components: {len(manifest.components)}")
        click.echo(f"Main Camera Position: {manifest.camera.position}")
        click.echo(f"Main Camera Look At: {manifest.camera.look_at}")
        click.echo(f"Simulation Duration: {manifest.simulation.duration_seconds}s")
        click.echo(f"Simulation Timesteps: {manifest.simulation.timesteps_per_second} per second")
        sys.exit(0)
    except FileNotFoundError as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
    except (yaml.YAMLError, ValidationError, ValueError) as e:
        click.echo(f"Failed to display manifest '{manifest_file}': {e}", err=True)
        sys.exit(1)
    except Exception as e:
        click.echo(f"An unexpected error occurred: {e}", err=True)
        sys.exit(1)

if __name__ == '__main__':
    cli()
