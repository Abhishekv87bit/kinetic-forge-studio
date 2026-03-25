import click
import yaml # Not strictly needed here, but might be for other manifest operations
import os
from pathlib import Path
import shutil

from kfs_core.manifest_parser import load_kfs_manifest, save_kfs_manifest
from kfs_core.manifest_models import KFSManifest, MeshGeometry
from kfs_core.assets.resolver import AssetResolver
from kfs_core.exceptions import AssetResolutionError, KFSBaseError

def get_unique_filename(directory: Path, desired_name: str) -> Path:
    """
    Generates a unique filename in the given directory.
    If 'desired_name' already exists, it appends a counter.
    Returns the full Path to the unique file within the directory.
    """
    base, ext = os.path.splitext(desired_name)
    candidate_path = directory / desired_name
    counter = 0
    while candidate_path.exists():
        counter += 1
        unique_name = f"{base}_{counter}{ext}"
        candidate_path = directory / unique_name
    return candidate_path


@click.command()
@click.argument(
    "manifest_file",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, readable=True, path_type=Path)
)
@click.argument(
    "output_dir",
    type=click.Path(file_okay=False, dir_okay=True, writable=True, path_type=Path)
)
@click.option(
    "--name",
    "-n",
    type=str,
    help="Optional name for the baked project. Defaults to the original manifest's name.",
)
def bake(manifest_file: Path, output_dir: Path, name: str):
    """
    Resolves all external assets referenced in a KFS manifest and bundles them
    into a self-contained output directory.

    MANIFEST_FILE: Path to the input .kfs.yaml or .kfs.json manifest file.
    OUTPUT_DIR: Path to the directory where the baked project will be saved.
                This directory will be created if it doesn't exist.
    """
    click.echo(f"Baking project from '{manifest_file}' to '{output_dir}'...")

    try:
        # 1. Load the manifest
        manifest = load_kfs_manifest(manifest_file)
        click.echo("Manifest loaded successfully.")

        # Override project name if provided
        if name:
            manifest.name = name

        # 2. Prepare output directory structure
        output_dir.mkdir(parents=True, exist_ok=True)
        baked_manifest_path = output_dir / f"{manifest_file.stem}_baked{manifest_file.suffix}"
        baked_assets_dir = output_dir / "assets"
        baked_assets_dir.mkdir(exist_ok=True)
        click.echo(f"Output directory '{output_dir}' and assets directory '{baked_assets_dir}' prepared.")

        # 3. Initialize Asset Resolver (without default_cache_dir, so it uses system temp for initial resolution)
        resolver = AssetResolver()

        # 4. Resolve assets, copy to output_dir/assets with unique names, and update manifest paths
        click.echo("Resolving external assets...")
        assets_resolved_count = 0
        
        # Keep track of resolved URIs and their final paths in the baked assets directory
        # to avoid re-resolving/re-copying if multiple manifest entries refer to the same external asset.
        resolved_asset_map: dict[str, Path] = {} # Maps original_uri to its absolute path in baked_assets_dir

        for geo_id, geometry in manifest.geometries.items():
            if isinstance(geometry, MeshGeometry):
                original_uri = geometry.path
                try:
                    if original_uri in resolved_asset_map:
                        # Asset already resolved and copied, reuse the baked path
                        baked_abs_path = resolved_asset_map[original_uri]
                        click.echo(f"  - Reusing baked asset '{baked_abs_path.name}' for '{original_uri}'")
                    else:
                        # Resolve the asset to a temporary location first
                        resolved_temp_path = resolver.resolve(original_uri)
                        
                        # Generate a unique filename in the baked assets directory
                        # based on the original asset's filename
                        unique_baked_path_abs = get_unique_filename(baked_assets_dir, resolved_temp_path.name)
                        
                        # Copy the asset from the temporary location to its unique path in the baked assets directory
                        shutil.copy2(resolved_temp_path, unique_baked_path_abs)
                        
                        baked_abs_path = unique_baked_path_abs
                        resolved_asset_map[original_uri] = baked_abs_path
                        assets_resolved_count += 1
                        
                        click.echo(f"  - Resolved '{original_uri}' and copied to '{baked_abs_path.name}'")

                    # Update the geometry's path in the manifest object
                    # This new path must be relative to the baked manifest file.
                    # e.g., if baked_abs_path is /output_dir/assets/unique_mesh.obj
                    # and baked_manifest_path is /output_dir/my_sculpture_baked.kfs.yaml
                    # new_relative_path should be "assets/unique_mesh.obj"
                    geometry.path = (Path("assets") / baked_abs_path.name).as_posix() # Store as posix path string

                except AssetResolutionError as e:
                    click.echo(f"  - Error resolving asset '{original_uri}': {e}", err=True)
                    raise # Re-raise to stop bake process if an asset fails
                except Exception as e:
                    click.echo(f"  - Unexpected error during asset resolution for '{original_uri}': {e}", err=True)
                    raise

        click.echo(f"Successfully processed {assets_resolved_count} unique external assets.")

        # 5. Save the modified manifest
        save_kfs_manifest(manifest, baked_manifest_path)
        click.echo(f"Baked manifest saved to '{baked_manifest_path}'.")
        click.echo(f"Project '{manifest.name}' baked successfully!")

    except KFSBaseError as e:
        click.echo(f"Bake failed: {e}", err=True)
        exit(1) # Indicate failure to the shell
    except Exception as e:
        click.echo(f"An unexpected error occurred during bake: {e}", err=True)
        exit(1) # Indicate failure to the shell
