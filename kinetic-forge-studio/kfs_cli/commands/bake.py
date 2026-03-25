import click
import os
import re
import tempfile
from pathlib import Path
import shutil

from kfs_core.manifest_parser import load_kfs_manifest, save_kfs_manifest
from kfs_core.manifest_models import KFSManifest, MeshGeometry
from kfs_core.assets.resolver import AssetResolver
from kfs_core.exceptions import (
    AssetResolutionError,
    KFSBaseError,
    KFSManifestValidationError,
    InvalidKFSManifestError,
    ManifestVersionMismatchError,
)


def _slugify(name: str) -> str:
    """Convert a project name to a filesystem-friendly slug."""
    slug = name.lower().strip()
    slug = re.sub(r'[^a-z0-9]+', '_', slug)
    slug = slug.strip('_')
    return slug


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
    type=click.Path(file_okay=False, dir_okay=True, path_type=Path)
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
    try:
        # 1. Load the manifest
        manifest = load_kfs_manifest(manifest_file)
        click.echo(f"Manifest loaded from '{manifest_file}'")

        # Bake requires at least one object in the manifest
        if not manifest.objects:
            raise KFSManifestValidationError(
                "Manifest must contain at least one object (minItems: 1 for 'objects').",
                errors=[{"type": "minItems", "msg": "minItems: objects list must not be empty", "loc": ("objects",)}],
            )

        # Override project name if provided
        if name:
            manifest.name = name

        # 2. Determine baked directory name
        if name:
            baked_dir_name = name
        else:
            baked_dir_name = _slugify(manifest.name) + "_baked"
        baked_dir = output_dir / baked_dir_name

        # 3. Collect mesh geometries that need asset resolution
        mesh_geos = {}
        for geo_id, geometry in manifest.geometries.items():
            if isinstance(geometry, MeshGeometry):
                mesh_geos[geo_id] = geometry

        # 4. Resolve assets BEFORE creating output directory.
        #    This ensures no output is created if resolution fails.
        has_assets = bool(mesh_geos)
        # resolved_sources maps original_uri -> (source_path, desired_filename, display_source)
        resolved_sources: dict[str, tuple[Path, str, str]] = {}

        if not has_assets:
            click.echo("No external assets found in manifest.")
        else:
            manifest_dir = manifest_file.parent
            # Use a unique temp cache dir for remote downloads to avoid stale cache
            cache_dir = Path(tempfile.mkdtemp(prefix="kfs_bake_cache_"))
            try:
                resolver = AssetResolver(default_cache_dir=cache_dir)

                for geo_id, geometry in mesh_geos.items():
                    original_uri = geometry.path

                    if original_uri in resolved_sources:
                        continue

                    # For local relative paths, resolve relative to manifest directory
                    source_path = manifest_dir / original_uri
                    if source_path.exists():
                        resolved_sources[original_uri] = (
                            source_path,
                            source_path.name,
                            str(source_path),
                        )
                    else:
                        # Try the asset resolver (for http:// etc.)
                        resolved_temp_path = resolver.resolve(original_uri)
                        resolved_sources[original_uri] = (
                            resolved_temp_path,
                            resolved_temp_path.name,
                            original_uri,
                        )

                # 5. All assets resolved -- create output dir and copy
                baked_dir.mkdir(parents=True, exist_ok=True)
                baked_assets_dir = baked_dir / "assets"
                baked_assets_dir.mkdir(exist_ok=True)

                for geo_id, geometry in mesh_geos.items():
                    original_uri = geometry.path
                    src_path, desired_filename, display_src = resolved_sources[original_uri]

                    unique_baked_path = get_unique_filename(baked_assets_dir, desired_filename)
                    shutil.copy2(src_path, unique_baked_path)

                    click.echo(f"Resolved asset '{display_src}' to '{unique_baked_path}'")

                    # Update the geometry's path to be relative within the baked package
                    geometry.path = (Path("assets") / unique_baked_path.name).as_posix()

            finally:
                # Clean up temp cache dir
                try:
                    shutil.rmtree(cache_dir, ignore_errors=True)
                except Exception:
                    pass

        # 6. Create output dir (if not already created for assets) and save manifest
        if not baked_dir.exists():
            baked_dir.mkdir(parents=True, exist_ok=True)

        baked_manifest_path = baked_dir / "kfs.yaml"
        save_kfs_manifest(manifest, baked_manifest_path)
        click.echo(f"Project baked to '{baked_dir}'")

    except (KFSManifestValidationError, InvalidKFSManifestError, ManifestVersionMismatchError) as e:
        error_type = type(e).__name__
        click.echo(f"Error baking project: {error_type}: {e}", err=True)
        raise SystemExit(1)
    except AssetResolutionError as e:
        click.echo(f"Error baking project: AssetResolutionError: {e}", err=True)
        raise SystemExit(1)
    except KFSBaseError as e:
        error_type = type(e).__name__
        click.echo(f"Error baking project: {error_type}: {e}", err=True)
        raise SystemExit(1)
    except SystemExit:
        raise
    except Exception as e:
        error_type = type(e).__name__
        click.echo(f"Error baking project: {error_type}: {e}", err=True)
        raise SystemExit(1)
