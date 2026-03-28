import json
import yaml
from pathlib import Path
from typing import Union, List, Dict, Any, Optional
import jsonschema
from jsonschema import ValidationError as JSONSchemaValidationError

from kfs_core.manifest_parser import _check_version_compatibility
from kfs_core.exceptions import (
    KFSManifestValidationError,
    ManifestVersionMismatchError,
    InvalidKFSManifestError,
    KFSBaseError
)
from kfs_core.constants import KFS_MANIFEST_VERSION
from kfs_core.validator.rules import SEMANTIC_VALIDATION_RULES, SemanticValidationError


class KFSManifestValidator:
    """
    Validates KFS manifest files against both their JSON Schema
    and custom semantic rules.
    """
    def __init__(self, schema_path: Optional[Union[str, Path]] = None):
        self._schema = self._load_schema(schema_path)
        self_schema_id = self._schema.get("$id", "")
        resolver = jsonschema.RefResolver(base_uri=self_schema_id, referrer=self._schema)
        self._validator = jsonschema.Draft7Validator(self._schema, resolver=resolver)

    def _get_default_schema_path(self) -> Path:
        """Determines the default schema path based on KFS_MANIFEST_VERSION."""
        schema_version_parts = KFS_MANIFEST_VERSION.split(".")
        if len(schema_version_parts) < 2:
            raise ValueError(f"KFS_MANIFEST_VERSION '{KFS_MANIFEST_VERSION}' is not in major.minor.patch format.")
        schema_version_major_minor = ".".join(schema_version_parts[:2])
        schema_filename = f"kfs_v{schema_version_major_minor}.json"
        return Path(__file__).parent / "schemas" / schema_filename

    def _load_schema(self, schema_path: Optional[Union[str, Path]] = None) -> Dict[str, Any]:
        """Loads the JSON schema from the specified path or default location."""
        if schema_path is None:
            schema_path = self._get_default_schema_path()

        schema_path = Path(schema_path)
        if not schema_path.exists():
            raise KFSBaseError(f"Schema file not found: {schema_path}")

        try:
            with open(schema_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            raise KFSBaseError(f"Invalid schema file format: {schema_path}: {e}") from e

    def validate_manifest_data(self, manifest_data: Dict[str, Any]) -> None:
        """
        Validates manifest data (dict) against JSON Schema and semantic rules.
        Raises appropriate exceptions on failure.
        """
        # 1. Version compatibility check (raises ManifestVersionMismatchError or InvalidKFSManifestError)
        _check_version_compatibility(manifest_data, KFS_MANIFEST_VERSION)

        all_errors: List[Dict[str, Any]] = []

        # 2. JSON Schema validation
        json_schema_errors = sorted(self._validator.iter_errors(manifest_data), key=str)
        for error in json_schema_errors:
            # For composite errors (oneOf, anyOf), find the best matching sub-error
            best = self._find_best_error(error)

            # For 'required' errors, path is at the parent level - use the missing property name
            if best.validator == "required":
                path_str = "/".join(map(str, best.absolute_path))
                if path_str:
                    path_str += "/" + best.message.split("'")[1]
                else:
                    path_str = best.message.split("'")[1]
            else:
                path_str = "/".join(map(str, best.absolute_path)) if best.absolute_path else ""

            all_errors.append({
                "type": "json_schema",
                "message": best.message,
                "path": path_str,
            })

        # 3. Semantic validation (only if JSON schema passes)
        if not all_errors:
            semantic_errors = self._run_semantic_checks(manifest_data)
            for s_error in semantic_errors:
                all_errors.append(s_error.to_dict())

        if all_errors:
            raise KFSManifestValidationError("Manifest validation failed.", errors=all_errors)

    def validate_manifest_file(self, file_path: Union[str, Path]) -> None:
        """
        Validates a manifest file (YAML or JSON) against JSON Schema and semantic rules.
        """
        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"Manifest file not found: {path}")

        file_extension = path.suffix.lower()
        try:
            with open(path, "r", encoding="utf-8") as f:
                if file_extension in (".yaml", ".yml"):
                    try:
                        manifest_data = yaml.safe_load(f)
                    except yaml.YAMLError as e:
                        raise InvalidKFSManifestError(f"Invalid YAML format in {path}: {e}") from e
                elif file_extension == ".json":
                    try:
                        manifest_data = json.load(f)
                    except json.JSONDecodeError as e:
                        raise InvalidKFSManifestError(f"Invalid JSON format in {path}: {e}") from e
                else:
                    raise InvalidKFSManifestError(f"Unsupported file type: {file_extension}")
        except (InvalidKFSManifestError, ManifestVersionMismatchError):
            raise
        except Exception as e:
            raise KFSBaseError(f"Error reading manifest file {path}: {e}") from e

        if not isinstance(manifest_data, dict):
            raise InvalidKFSManifestError(f"Manifest content is not a valid dictionary in {path}")

        # Check for likely YAML/JSON structural issues (e.g., incorrect indentation
        # causing keys to not be nested properly)
        if file_extension in (".yaml", ".yml"):
            # If expected dict fields are None, it's likely a YAML indentation issue
            for field in ("geometries", "materials"):
                if field in manifest_data and manifest_data[field] is None:
                    raise InvalidKFSManifestError(
                        f"Invalid YAML format in {path}: "
                        f"'{field}' parsed as null, likely due to incorrect indentation."
                    )

        self.validate_manifest_data(manifest_data)

    @staticmethod
    def _find_best_error(error) -> Any:
        """
        For composite schema errors (oneOf/anyOf), find the most specific sub-error.
        Returns the best matching error with the deepest path.
        """
        if not error.context:
            return error
        # Find the sub-error with the deepest absolute_path (most specific)
        best = error
        best_depth = len(list(error.absolute_path))
        for sub in error.context:
            sub_depth = len(list(sub.absolute_path))
            if sub_depth > best_depth:
                best = sub
                best_depth = sub_depth
            elif sub_depth == best_depth and sub.validator == "type":
                # Prefer 'type' errors over others at same depth
                best = sub
                best_depth = sub_depth
        return best

    def _run_semantic_checks(self, manifest_data: Dict[str, Any]) -> List[SemanticValidationError]:
        """Run semantic validation rules on raw manifest data."""
        errors: List[SemanticValidationError] = []

        # Check duplicate object IDs
        objects = manifest_data.get("objects", [])
        seen_obj_ids: Dict[str, int] = {}
        for i, obj in enumerate(objects):
            if isinstance(obj, dict):
                obj_id = obj.get("id")
            else:
                obj_id = getattr(obj, "id", None)
            if obj_id is None:
                continue
            if obj_id in seen_obj_ids:
                errors.append(SemanticValidationError(
                    code="DUPLICATE_OBJECTS_ID",
                    message=f"Duplicate ID '{obj_id}' found in 'objects' collection.",
                    path=["objects", i, "id"],
                    value=obj_id
                ))
            else:
                seen_obj_ids[obj_id] = i

        # Check duplicate geometry IDs (geometries is a dict, check for duplicate 'id' values across keys)
        geometries = manifest_data.get("geometries", {})
        if isinstance(geometries, dict):
            seen_geo_ids: Dict[str, str] = {}  # id -> dict key
            for key, geo in geometries.items():
                if isinstance(geo, dict):
                    geo_id = geo.get("id")
                else:
                    geo_id = getattr(geo, "id", None)
                if geo_id is None:
                    continue
                if geo_id in seen_geo_ids:
                    errors.append(SemanticValidationError(
                        code="DUPLICATE_GEOMETRIES_ID",
                        message=f"Duplicate ID '{geo_id}' found in 'geometries' collection.",
                        path=["geometries", key, "id"],
                        value=geo_id
                    ))
                else:
                    seen_geo_ids[geo_id] = key

        # Check duplicate material IDs
        materials = manifest_data.get("materials", {})
        if isinstance(materials, dict):
            seen_mat_ids: Dict[str, str] = {}
            for key, mat in materials.items():
                if isinstance(mat, dict):
                    mat_id = mat.get("id")
                else:
                    mat_id = getattr(mat, "id", None)
                if mat_id is None:
                    continue
                if mat_id in seen_mat_ids:
                    errors.append(SemanticValidationError(
                        code="DUPLICATE_MATERIALS_ID",
                        message=f"Duplicate ID '{mat_id}' found in 'materials' collection.",
                        path=["materials", key, "id"],
                        value=mat_id
                    ))
                else:
                    seen_mat_ids[mat_id] = key

        # Check referenced geometry and material IDs exist
        available_geo_ids = set()
        if isinstance(geometries, dict):
            available_geo_ids = set(geometries.keys())

        available_mat_ids = set()
        if isinstance(materials, dict):
            available_mat_ids = set(materials.keys())

        for i, obj in enumerate(objects):
            if isinstance(obj, dict):
                geo_ref = obj.get("geometry_id")
                mat_ref = obj.get("material_id")
            else:
                geo_ref = getattr(obj, "geometry_id", None)
                mat_ref = getattr(obj, "material_id", None)

            if geo_ref and geo_ref not in available_geo_ids:
                errors.append(SemanticValidationError(
                    code="MISSING_GEOMETRY_REFERENCE",
                    message=f"Geometry reference '{geo_ref}' not found in available definitions.",
                    path=["objects", i, "geometry_id"],
                    value=geo_ref
                ))

            if mat_ref and mat_ref not in available_mat_ids:
                errors.append(SemanticValidationError(
                    code="MISSING_MATERIAL_REFERENCE",
                    message=f"Material reference '{mat_ref}' not found in available definitions.",
                    path=["objects", i, "material_id"],
                    value=mat_ref
                ))

        return errors
