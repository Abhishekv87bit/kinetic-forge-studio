
import pytest
from pydantic import BaseModel, Field, ValidationError
from typing import Type, Literal, List, Union, Dict, Any, get_origin, get_args
import os
import sys
import inspect

# Assume these classes exist in their respective modules.
# We will mock CustomTypeDefinition and PluginManager for the test.

# Mock CustomTypeDefinition
class CustomTypeDefinition:
    """A mock for CustomTypeDefinition to simulate plugin definitions."""
    def __init__(
        self,
        name: str,
        type_model: Type[BaseModel],
        target_path: str,
        action: Literal["extend_union", "add_field", "replace_field"],
        field_name: str | None = None
    ):
        self.name = name
        self.type_model = type_model
        self.target_path = target_path
        self.action = action
        self.field_name = field_name

# Mock PluginManager
class PluginManager:
    """A mock for PluginManager to simulate its behavior for testing."""
    _instance = None
    _custom_types: Dict[str, CustomTypeDefinition] = {}
    _registered_models: Dict[str, Type[BaseModel]] = {}
    _loaded_plugin_paths: List[str] = []

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super(PluginManager, cls).__new__(cls, *args, **kwargs)
        return cls._instance

    def register_custom_type(self, custom_type_def: CustomTypeDefinition):
        """Registers a single custom type definition."""
        if custom_type_def.name in self._custom_types:
            raise ValueError(f"Custom type '{custom_type_def.name}' already registered.")
        self._custom_types[custom_type_def.name] = custom_type_def
        self._registered_models[custom_type_def.type_model.__name__] = custom_type_def.type_model

    def load_plugins_from_path(self, plugin_paths: List[str]):
        """
        Mocks loading plugins. In a real scenario, this would import modules
        and call their registration functions. For testing, we just record paths.
        """
        self._loaded_plugin_paths.extend(plugin_paths)

    def get_registered_models(self) -> Dict[str, Type[BaseModel]]:
        return self._registered_models

    def reset(self):
        """Resets the plugin manager for clean testing."""
        self._custom_types = {}
        self._registered_models = {}
        self._loaded_plugin_paths = []

    def apply_plugins(self, base_schema: Type[BaseModel]) -> Type[BaseModel]:
        """
        Mocks the application of plugins to a base schema.
        This is a simplified implementation for testing purposes, mimicking
        Pydantic's dynamic model creation or modification.
        """
        # Collect current fields and annotations from the base schema
        current_annotations = base_schema.__annotations__.copy()
        current_fields = {name: (field.annotation, field.default) for name, field in base_schema.model_fields.items()}

        for custom_type_def in self._custom_types.values():
            if custom_type_def.target_path == base_schema.__name__:
                if custom_type_def.action == "add_field" and custom_type_def.field_name:
                    current_fields[custom_type_def.field_name] = (custom_type_def.type_model, Field(...))
                    current_annotations[custom_type_def.field_name] = custom_type_def.type_model
                elif custom_type_def.action == "extend_union" and custom_type_def.field_name:
                    if custom_type_def.field_name in current_annotations:
                        original_type = current_annotations[custom_type_def.field_name]
                        # Handle List[Union[...]] or Union[...] directly
                        if get_origin(original_type) is List:
                            inner_type = get_args(original_type)[0]
                            if get_origin(inner_type) is Union:
                                current_annotations[custom_type_def.field_name] = List[Union[*get_args(inner_type), custom_type_def.type_model]]
                            else: # List[SingleType] -> List[Union[SingleType, NewType]]
                                current_annotations[custom_type_def.field_name] = List[Union[inner_type, custom_type_def.type_model]]
                        elif get_origin(original_type) is Union:
                            current_annotations[custom_type_def.field_name] = Union[*get_args(original_type), custom_type_def.type_model]
                        else: # SingleType -> Union[SingleType, NewType]
                            current_annotations[custom_type_def.field_name] = Union[original_type, custom_type_def.type_model]
                    else:
                        raise ValueError(f"Cannot extend union for non-existent field '{custom_type_def.field_name}' in {base_schema.__name__}")
                elif custom_type_def.action == "replace_field" and custom_type_def.field_name:
                    current_fields[custom_type_def.field_name] = (custom_type_def.type_model, Field(...))
                    current_annotations[custom_type_def.field_name] = custom_type_def.type_model
            
            # Handle nested paths like "KineticForgeSchema.assets" for extending inner union types
            if custom_type_def.target_path == "KineticForgeSchema.assets" and custom_type_def.action == "extend_union":
                if "assets" in current_annotations and get_origin(current_annotations["assets"]) is List:
                    asset_union_type = get_args(current_annotations["assets"])[0]
                    if get_origin(asset_union_type) is Union:
                        new_asset_union_args = (*get_args(asset_union_type), custom_type_def.type_model)
                        current_annotations["assets"] = List[Union[new_asset_union_args]]
                    else: # e.g. List[StandardGeometry] -> List[Union[StandardGeometry, MyCustomAsset]]
                        current_annotations["assets"] = List[Union[asset_union_type, custom_type_def.type_model]]

        # Create a new Pydantic model class dynamically
        # This simulates `pydantic.create_model` by creating a new type and setting its attributes.
        # This is a critical simplification for the mock within the given constraints.
        
        # Prepare the namespace for the new model
        new_model_namespace = {
            "__annotations__": current_annotations,
            "__module__": base_schema.__module__, # Important for Pydantic to recognize it
        }

        # Dynamically create FieldInfo objects for model_fields in Pydantic V2 style
        new_model_fields = {}
        for field_name, (field_type, field_default) in current_fields.items():
            if field_default is Field(...):
                new_model_fields[field_name] = Field(annotation=field_type) # Required field
            else:
                new_model_fields[field_name] = Field(annotation=field_type, default=field_default)

        NewSchema = type(
            f"Extended{base_schema.__name__}",
            (base_schema,),
            new_model_namespace
        )

        return NewSchema

# --- Dummy KFS Schema for Testing ---
class BaseAsset(BaseModel):
    id: str = Field(..., description="Unique identifier for the asset.")
    name: str = Field(..., description="Human-readable name for the asset.")
    type: str = Field(..., description="The type of asset.")

class StandardGeometry(BaseAsset):
    type: Literal["standard_geometry"] = "standard_geometry"
    shape: str = Field(..., description="Geometric shape, e.g., 'box', 'sphere'.")

class KineticForgeSchema(BaseModel):
    version: Literal["v1"] = "v1"
    assets: List[Union[StandardGeometry]] = Field(default_factory=list, description="List of assets in the manifest.")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="General metadata for the manifest.")

# --- Custom Types for Testing ---
class MyCustomAsset(BaseAsset):
    type: Literal["my_custom_asset"] = "my_custom_asset"
    custom_property: str = Field(..., min_length=5, description="A unique property for MyCustomAsset.")

class AnotherCustomAsset(BaseAsset):
    type: Literal["another_custom_asset"] = "another_custom_asset"
    another_prop: int = Field(..., ge=0, description="Another custom property.")

class CustomMetadataField(BaseModel):
    author: str
    timestamp: str

# --- Tests for PluginManager ---

@pytest.fixture(autouse=True)
def reset_plugin_manager():
    """Fixture to ensure a clean PluginManager state before each test."""
    PluginManager().reset()
    yield

def test_plugin_manager_registers_custom_type():
    """Verifies the plugin manager can register a custom type."""
    manager = PluginManager()
    
    custom_def = CustomTypeDefinition(
        name="my_asset_plugin",
        type_model=MyCustomAsset,
        target_path="KineticForgeSchema.assets",
        action="extend_union"
    )
    manager.register_custom_type(custom_def)
    
    registered_models = manager.get_registered_models()
    assert "MyCustomAsset" in registered_models
    assert registered_models["MyCustomAsset"] is MyCustomAsset

def test_plugin_manager_prevents_duplicate_registration():
    """Ensures duplicate custom type registration raises an error."""
    manager = PluginManager()
    
    custom_def = CustomTypeDefinition(
        name="my_asset_plugin",
        type_model=MyCustomAsset,
        target_path="KineticForgeSchema.assets",
        action="extend_union"
    )
    manager.register_custom_type(custom_def)
    
    with pytest.raises(ValueError, match="already registered"):
        manager.register_custom_type(custom_def)

def test_plugin_manager_loads_plugins_from_path_mock():
    """Verifies the plugin manager mock records plugin paths."""
    manager = PluginManager()
    mock_plugin_path = "/tmp/my_plugins"
    manager.load_plugins_from_path([mock_plugin_path])
    assert mock_plugin_path in manager._loaded_plugin_paths

def test_plugin_manager_applies_custom_asset_type_to_schema():
    """
    Tests that the plugin manager correctly extends the 'assets' union type
    in KineticForgeSchema with a custom asset.
    """
    manager = PluginManager()
    
    custom_def = CustomTypeDefinition(
        name="my_asset_plugin",
        type_model=MyCustomAsset,
        target_path="KineticForgeSchema.assets",
        action="extend_union"
    )
    manager.register_custom_type(custom_def)
    
    ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)
    
    # Assert that the new schema is a Pydantic model and distinct from the original
    assert issubclass(ExtendedKineticForgeSchema, KineticForgeSchema)
    assert ExtendedKineticForgeSchema is not KineticForgeSchema
    
    # Verify the 'assets' field now accepts MyCustomAsset
    assert "assets" in ExtendedKineticForgeSchema.model_fields
    
    # Test valid data with custom asset
    valid_data = {
        "version": "v1",
        "assets": [
            {"id": "geo1", "name": "box1", "type": "standard_geometry", "shape": "box"},
            {"id": "custom1", "name": "my_custom_thing", "type": "my_custom_asset", "custom_property": "some_value"}
        ],
        "metadata": {}
    }
    extended_schema_instance = ExtendedKineticForgeSchema(**valid_data)
    assert len(extended_schema_instance.assets) == 2
    assert isinstance(extended_schema_instance.assets[1], MyCustomAsset)
    assert extended_schema_instance.assets[1].custom_property == "some_value"

    # Test invalid data for custom asset (e.g., missing required field)
    invalid_data_missing_prop = {
        "version": "v1",
        "assets": [
            {"id": "custom1", "name": "my_custom_thing", "type": "my_custom_asset"}
        ]
    }
    with pytest.raises(ValidationError):
        ExtendedKineticForgeSchema(**invalid_data_missing_prop)

    # Test invalid custom asset type
    invalid_data_wrong_type = {
        "version": "v1",
        "assets": [
            {"id": "wrong1", "name": "wrong_thing", "type": "unknown_asset", "data": "abc"}
        ]
    }
    with pytest.raises(ValidationError):
        ExtendedKineticForgeSchema(**invalid_data_wrong_type)


def test_plugin_manager_applies_multiple_custom_asset_types():
    """
    Tests that the plugin manager correctly extends the 'assets' union type
    with multiple custom asset types.
    """
    manager = PluginManager()
    
    custom_def1 = CustomTypeDefinition(
        name="my_asset_plugin",
        type_model=MyCustomAsset,
        target_path="KineticForgeSchema.assets",
        action="extend_union"
    )
    custom_def2 = CustomTypeDefinition(
        name="another_asset_plugin",
        type_model=AnotherCustomAsset,
        target_path="KineticForgeSchema.assets",
        action="extend_union"
    )
    manager.register_custom_type(custom_def1)
    manager.register_custom_type(custom_def2)
    
    ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)
    
    valid_data = {
        "version": "v1",
        "assets": [
            {"id": "geo1", "name": "box1", "type": "standard_geometry", "shape": "box"},
            {"id": "custom1", "name": "my_custom_thing", "type": "my_custom_asset", "custom_property": "some_value"},
            {"id": "another1", "name": "another_thing", "type": "another_custom_asset", "another_prop": 123}
        ],
        "metadata": {}
    }
    extended_schema_instance = ExtendedKineticForgeSchema(**valid_data)
    assert len(extended_schema_instance.assets) == 3
    assert isinstance(extended_schema_instance.assets[1], MyCustomAsset)
    assert isinstance(extended_schema_instance.assets[2], AnotherCustomAsset)


def test_plugin_manager_adds_new_field_to_schema():
    """
    Tests that the plugin manager can add a new field directly to the
    KineticForgeSchema.
    """
    manager = PluginManager()
    
    custom_def = CustomTypeDefinition(
        name="custom_metadata_field_plugin",
        type_model=CustomMetadataField,
        target_path="KineticForgeSchema",
        action="add_field",
        field_name="project_info"
    )
    manager.register_custom_type(custom_def)
    
    ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)
    
    # Verify the new field exists
    assert "project_info" in ExtendedKineticForgeSchema.model_fields
    assert ExtendedKineticForgeSchema.model_fields["project_info"].annotation is CustomMetadataField
    
    # Test valid data with new field
    valid_data = {
        "version": "v1",
        "assets": [],
        "metadata": {},
        "project_info": {"author": "John Doe", "timestamp": "2023-10-27T10:00:00Z"}
    }
    extended_schema_instance = ExtendedKineticForgeSchema(**valid_data)
    assert isinstance(extended_schema_instance.project_info, CustomMetadataField)
    assert extended_schema_instance.project_info.author == "John Doe"

    # Test invalid data for new field
    invalid_data_missing_field = {
        "version": "v1",
        "assets": [],
        "metadata": {},
        "project_info": {"author": "Jane Doe"} # Missing timestamp
    }
    with pytest.raises(ValidationError):
        ExtendedKineticForgeSchema(**invalid_data_missing_field)

def test_plugin_manager_replaces_field_in_schema():
    """
    Tests that the plugin manager can replace an existing field in the
    KineticForgeSchema with a custom type.
    """
    manager = PluginManager()

    # Define a custom field that will replace 'metadata'
    class ReplacedMetadataField(BaseModel):
        new_format_key: str
        new_format_value: int

    custom_def = CustomTypeDefinition(
        name="replace_metadata_plugin",
        type_model=ReplacedMetadataField,
        target_path="KineticForgeSchema",
        action="replace_field",
        field_name="metadata"
    )
    manager.register_custom_type(custom_def)

    ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)

    # Verify the 'metadata' field now has the new type
    assert "metadata" in ExtendedKineticForgeSchema.model_fields
    assert ExtendedKineticForgeSchema.model_fields["metadata"].annotation is ReplacedMetadataField
    
    # Test valid data with replaced field
    valid_data = {
        "version": "v1",
        "assets": [],
        "metadata": {"new_format_key": "abc", "new_format_value": 123}
    }
    extended_schema_instance = ExtendedKineticForgeSchema(**valid_data)
    assert isinstance(extended_schema_instance.metadata, ReplacedMetadataField)
    assert extended_schema_instance.metadata.new_format_key == "abc"

    # Test invalid data for replaced field
    invalid_data_missing_field = {
        "version": "v1",
        "assets": [],
        "metadata": {"new_format_key": "xyz"} # Missing new_format_value
    }
    with pytest.raises(ValidationError):
        ExtendedKineticForgeSchema(**invalid_data_missing_field)

    invalid_data_wrong_type = {
        "version": "v1",
        "assets": [],
        "metadata": {"new_format_key": "xyz", "new_format_value": "not_an_int"}
    }
    with pytest.raises(ValidationError):
        ExtendedKineticForgeSchema(**invalid_data_wrong_type)
