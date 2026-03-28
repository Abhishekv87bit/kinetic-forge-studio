from typing import List, Dict, Any, Union
from kfs_core.manifest_models import KFSManifest, KFSObject
from kfs_core.exceptions import KFSManifestValidationError

class SemanticValidationError:
    """Represents a single semantic validation error."""
    def __init__(self, code: str, message: str, path: List[Union[str, int]] = None, value: Any = None):
        self.code = code
        self.message = message
        self.path = path if path is not None else []
        self.value = value

    def to_dict(self) -> Dict[str, Any]:
        """Converts the error into a dictionary suitable for KFSManifestValidationError."""
        return {
            "type": "semantic",
            "code": self.code,
            "message": self.message,
            "path": "/".join(map(str, self.path)),
            "value": self.value
        }

def _check_duplicates_in_list(items: List[Any], id_key: str, collection_name: str, parent_path: List[Union[str, int]]) -> List[SemanticValidationError]:
    """Helper to check for duplicate IDs in a list of items."""
    errors = []
    seen_ids = set()
    for i, item in enumerate(items):
        item_id = getattr(item, id_key, None)
        if item_id is None:
            # This case might be caught by Pydantic 'id' field validation already.
            # But adding a safeguard.
            errors.append(SemanticValidationError(
                code="MISSING_ID",
                message=f"Item in {collection_name} at index {i} is missing an ID.",
                path=parent_path + [i],
                value=item
            ))
            continue
        
        if item_id in seen_ids:
            errors.append(SemanticValidationError(
                code=f"DUPLICATE_{collection_name.upper().replace(' ', '_')}_ID",
                message=f"Duplicate ID '{item_id}' found in '{collection_name}' collection.",
                path=parent_path + [i, id_key],
                value=item_id
            ))
        seen_ids.add(item_id)
    return errors


def _check_referenced_ids_exist(
    referenced_ids: List[str],
    available_ids: set,
    code_prefix: str,
    entity_name: str,
    path: List[Union[str, int]]
) -> List[SemanticValidationError]:
    """Helper to check that referenced IDs exist in the available set."""
    errors = []
    for ref_id in referenced_ids:
        if ref_id not in available_ids:
            errors.append(SemanticValidationError(
                code=f"MISSING_{code_prefix}_REFERENCE",
                message=f"{entity_name} reference '{ref_id}' not found in available definitions.",
                path=path,
                value=ref_id
            ))
    return errors


def validate_unique_component_ids(manifest: KFSManifest) -> List[SemanticValidationError]:
    """
    Ensures that IDs for geometries, materials, and objects are unique within their respective collections.
    Pydantic dict keys for geometries and materials already enforce uniqueness, so this mainly
    focuses on the 'objects' list.
    """
    errors: List[SemanticValidationError] = []
    
    # KFSManifest.geometries and KFSManifest.materials are dictionaries, 
    # so their keys are inherently unique due to Pydantic's dict handling.
    # The primary check here is for the list of objects.
    errors.extend(_check_duplicates_in_list(manifest.objects, "id", "objects", ["objects"]))
            
    return errors

def validate_referenced_ids_exist(manifest: KFSManifest) -> List[SemanticValidationError]:
    """
    Ensures that 'geometry_id' and 'material_id' in KFSObjects refer to existing definitions.
    """
    errors: List[SemanticValidationError] = []
    
    defined_geometry_ids = set(manifest.geometries.keys())
    defined_material_ids = set(manifest.materials.keys())

    for i, obj in enumerate(manifest.objects):
        if obj.geometry_id is not None and obj.geometry_id not in defined_geometry_ids:
            errors.append(SemanticValidationError(
                code="UNKNOWN_GEOMETRY_REFERENCE",
                message=f"Object '{obj.id}' references unknown geometry ID '{obj.geometry_id}'.",
                path=["objects", i, "geometry_id"],
                value=obj.geometry_id
            ))

        if obj.material_id is not None and obj.material_id not in defined_material_ids:
            errors.append(SemanticValidationError(
                code="UNKNOWN_MATERIAL_REFERENCE",
                message=f"Object '{obj.id}' references unknown material ID '{obj.material_id}'.",
                path=["objects", i, "material_id"],
                value=obj.material_id
            ))
            
    return errors

# List of all semantic validation rule functions to be executed
SEMANTIC_VALIDATION_RULES = [
    validate_unique_component_ids,
    validate_referenced_ids_exist,
]
