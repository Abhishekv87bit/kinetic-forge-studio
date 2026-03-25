import json
import yaml # Required for loading YAML files
from pathlib import Path
from typing import Union, List, Dict, Any, Optional
import jsonschema
from jsonschema import ValidationError as JSONSchemaValidationError
from pydantic import ValidationError as PydanticValidationError

from kfs_core.manifest_models import KFSManifest
from kfs_core.manifest_parser import load_kfs_manifest, _check_version_compatibility
from kfs_core.exceptions import KFSManifestValidationError, ManifestVersionMismatchError, KFSBaseError
from kfs_core.constants import KFS_MANIFEST_VERSION
from kfs_core.validator.rules import SEMANTIC_VALIDATION_RULES, SemanticValidationError

class KFSManifestValidator:
    """
    Validates KFS manifest files against both their JSON Schema
    and custom semantic rules.
    """
    def __init__(self, schema_path: Optional[Union[str, Path]] = None):
        self._schema = self._load_schema(schema_path)
        # Using Draft7Validator because our schema defines "$schema": "http://json-schema.org/draft-07/schema#"
        # Add a RefResolver to correctly resolve internal $refs within the schema
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
        
        # The schema is located in kfs_core/validator/schemas/ relative to the project root.
        # This file is kfs_core/validator/manifest_validator.py.
        # So, the path is `Path(__file__).parent / "schemas" / schema_filename`
        return Path(__file__).parent / "schemas" / schema_filename

    def _load_schema(self, schema_path: Optional[Union[str, Path]] = None) -> Dict[str, Any]:
        """Loads the JSON schema from the specified path or default location."""
        if schema_path is None:
            schema_path = self._get_default_schema_path()
        
        schema_path = Path(schema_path) # Ensure it's a Path object
        if not schema_path.exists():
            raise FileNotFoundError(f"KFS Manifest JSON Schema not found at: {schema_path}")

        try:
            with open(schema_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            raise KFSBaseError(f"Failed to parse JSON Schema from {schema_path}: {e}") from e

    def validate(self, manifest_input: Union[str, Path, Dict[str, Any]]) -> KFSManifest:
        """
        Validates a KFS manifest against its JSON Schema and semantic rules.

        Args:
            manifest_input (Union[str, Path, Dict[str, Any]]): The manifest content.
                Can be a file path (str or Path) or a pre-parsed dictionary.

        Returns:
            KFSManifest: The validated Pydantic model instance.

        Raises:
            KFSManifestValidationError: If any structural or semantic validation fails.
            FileNotFoundError: If a file path is provided but the file does not exist.
            TypeError: If manifest_input is of an unsupported type.
            KFSBaseError: For issues like schema loading or parsing itself.
        """
        all_errors: List[Dict[str, Any]] = []
        raw_manifest_data: Optional[Dict[str, Any]] = None
        kfs_manifest_model: Optional[KFSManifest] = None

        if isinstance(manifest_input, (str, Path)):
            file_path = Path(manifest_input)
            if not file_path.exists():
                raise FileNotFoundError(f"Manifest file not found: {file_path}")
            
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    if file_path.suffix.lower() in ['.yaml', '.yml']:
                        raw_manifest_data = yaml.safe_load(f)
                    elif file_path.suffix.lower() == '.json':
                        raw_manifest_data = json.load(f)
                    else:
                        raise KFSManifestValidationError(f"Unsupported file type for structural validation: {file_path.suffix}. Must be .yaml, .yml, or .json.")
            except (yaml.YAMLError, json.JSONDecodeError) as e:
                # Catch basic syntax errors during loading of the file itself
                raise KFSManifestValidationError(f"Invalid manifest file syntax for {file_path}: {e}") from e
            except Exception as e:
                raise KFSManifestValidationError(f"Failed to load manifest file {file_path}: {e}") from e

            # Use load_kfs_manifest for Pydantic validation and version compatibility for file inputs.
            # This centralizes Pydantic-level validation logic (including version checks) for files.
            try:
                kfs_manifest_model = load_kfs_manifest(file_path)
            except KFSManifestValidationError as e:
                # load_kfs_manifest returns KFSManifestValidationError with a list of error dicts.
                all_errors.extend(e.errors)
            except KFSBaseError as e: # Catch version mismatch or other parser-specific errors not wrapped by KFSManifestValidationError
                all_errors.append({"type": "parser_error", "message": str(e), "path": "root", "details": e.__class__.__name__})
            except Exception as e:
                all_errors.append({"type": "unexpected_parsing_error", "message": str(e), "path": "root", "details": e.__class__.__name__})

        elif isinstance(manifest_input, dict):
            raw_manifest_data = manifest_input
            # For dictionary input, manually perform version check and Pydantic validation
            try:
                _check_version_compatibility(raw_manifest_data, KFS_MANIFEST_VERSION)
                kfs_manifest_model = KFSManifest(**raw_manifest_data)
            except PydanticValidationError as e:
                for error in e.errors():
                    all_errors.append({
                        "type": "pydantic",
                        "message": error['msg'],
                        "path": "/".join(map(str, error['loc'])),
                        "field": error['loc'][-1] if error['loc'] else None,
                        "error_type": error['type'],
                        "context": error.get('ctx')
                    })
            except ManifestVersionMismatchError as e:
                 all_errors.append({
                    "type": "version_check",
                    "message": str(e),
                    "path": "kfs_version",
                    "value": raw_manifest_data.get("kfs_version"),
                    "details": e.__class__.__name__
                })
            except KFSBaseError as e: # Catch other parser-specific issues like missing version (InvalidKFSManifestError)
                all_errors.append({"type": "parser_error", "message": str(e), "path": "root", "details": e.__class__.__name__})
            except Exception as e:
                 all_errors.append({
                    "type": "unexpected_pydantic_error",
                    "message": str(e),
                    "path": "root",
                    "details": e.__class__.__name__
                })
        else:
            raise TypeError("manifest_input must be a file path (str/Path) or a dictionary.")
        
        # 1. JSON Schema Structural Validation (always run on raw data if available)
        # This is crucial as Pydantic may silently drop extra fields or coerce types,
        # which JSON Schema validation would explicitly flag as errors against the schema.
        if raw_manifest_data:
            json_schema_errors = sorted(self._validator.iter_errors(raw_manifest_data), key=str)
            for error in json_schema_errors:
                all_errors.append({
                    "type": "structural_json_schema", # Differentiate from Pydantic errors
                    "message": error.message,
                    "path": "/".join(map(str, error.path)),
                    "schema_path": "/".join(map(str, error.schema_path)),
                    "validator": error.validator,
                    "validator_value": error.validator_value,
                    "instance": str(error.instance) # Convert instance to string for JSON serializability
                })

        # 2. Custom Semantic Validation (only if Pydantic model was successfully created)
        # Semantic rules operate on the rich, validated Pydantic model.
        if kfs_manifest_model:
            for rule_func in SEMANTIC_VALIDATION_RULES:
                semantic_rule_errors = rule_func(kfs_manifest_model)
                for s_error in semantic_rule_errors:
                    all_errors.append(s_error.to_dict()) # SemanticValidationError.to_dict() provides the expected dict format

        if all_errors:
            # Aggregate all errors and raise a single KFSManifestValidationError
            raise KFSManifestValidationError("Manifest validation failed.", errors=all_errors)
        
        if kfs_manifest_model is None:
            # This case implies that no errors were explicitly captured, but the Pydantic model
            # could not be created, indicating a logic flaw within the validator itself.
            raise KFSManifestValidationError("Manifest could not be fully validated into a KFSManifest model due to an uncaptured internal error.")

        return kfs_manifest_model
