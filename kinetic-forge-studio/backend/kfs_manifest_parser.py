import yaml

from backend.kfs_manifest_types import GeometrySpec, SimulationSpec, KFSManifestParsed


class KFSManifestParser:
    """Parses KFS manifest YAML content into structured types."""

    def parse_manifest(self, content: str):
        """Parse a YAML string into a KFSManifestParsed object with geometry and simulation specs.

        Args:
            content: A YAML string representing a KFS manifest.

        Returns:
            A KFSManifestParsed object with geometry and simulation attributes.

        Raises:
            ValueError: If the content is empty, not valid YAML, not a dict,
                        or missing required sections.
        """
        if not content or not content.strip():
            raise ValueError("Manifest content cannot be empty")

        try:
            data = yaml.safe_load(content)
        except yaml.YAMLError as e:
            raise ValueError(f"Invalid YAML syntax: {e}") from e

        if data is None:
            raise ValueError("Manifest content cannot be empty")

        if not isinstance(data, dict):
            raise ValueError("Manifest content must be a dictionary.")

        # Validate geometry section
        geometry_data = data.get("geometry")
        if not isinstance(geometry_data, dict):
            raise ValueError("Missing or invalid 'geometry' section.")

        geometry_type = geometry_data.get("type")
        if geometry_type is None:
            raise ValueError("Geometry 'type' is required.")
        if not isinstance(geometry_type, str):
            raise ValueError("Geometry 'type' must be a string.")

        geometry_params = geometry_data.get("parameters")
        if geometry_params is not None and not isinstance(geometry_params, dict):
            raise ValueError("Geometry 'parameters' must be a dictionary.")

        # Validate simulation section
        simulation_data = data.get("simulation")
        if not isinstance(simulation_data, dict):
            raise ValueError("Missing or invalid 'simulation' section.")

        simulation_type = simulation_data.get("type")
        if simulation_type is None:
            raise ValueError("Simulation 'type' is required.")
        if not isinstance(simulation_type, str):
            raise ValueError("Simulation 'type' must be a string.")

        simulation_params = simulation_data.get("parameters")
        if simulation_params is not None and not isinstance(simulation_params, dict):
            raise ValueError("Simulation 'parameters' must be a dictionary.")

        # Build result
        geometry = GeometrySpec(
            type=geometry_type,
            parameters=geometry_params if geometry_params else {}
        )
        simulation = SimulationSpec(
            type=simulation_type,
            parameters=simulation_params if simulation_params else {}
        )

        return KFSManifestParsed(geometry=geometry, simulation=simulation)
