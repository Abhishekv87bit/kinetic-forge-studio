import click
from kfs_core.constants import KFS_MANIFEST_VERSION
from kfs_cli.commands.generate import generate

@click.group()
@click.version_option(version=KFS_MANIFEST_VERSION, prog_name="kfs")
def cli():
    """
    Kinetic Forge Studio (KFS) CLI.
    Manage your kinetic sculpture manifests.
    """
    pass

cli.add_command(generate)

if __name__ == "__main__":
    cli()