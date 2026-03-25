
import pytest
import importlib
import importlib.util
import tempfile
import os
from pathlib import Path
import sys
from typing import List, Dict, Type, Any, Optional
from pydantic import BaseModel, Field, ValidationError, create_model

# --- Mocks for KFS backend modules ---
# These mocks simulate the actual backend modules.
# They are placed in sys.modules to be discoverable by the plugin manager and plugins.

# Mock for `backend.kfs_manifest.extensibility.custom_types`
class MockCustomTypesModule:
    _CUSTOM_MODELS_REGISTRY: Dict[str, Type[BaseModel]] = {}

    def register_custom_model(self, model_name: str, model_class: Type[BaseModel]):
        if not issubclass(model_class, BaseModel):
            raise TypeError(f"Registered model {model_name} must inherit from pydantic.BaseModel")
        self._CUSTOM_MODELS_REGISTRY[model_name] = model_class

    def get_registered_custom_models(self) -> Dict[str, Type[BaseModel]]:
        return self._CUSTOM_MODELS_REGISTRY.copy()

    def clear_custom_models_registry(self):
        self._CUSTOM_MODELS_REGISTRY.clear()

mock_custom_types_instance = MockCustomTypesModule() # Instantiate the mock module

# Mock for `backend.kfs_manifest.schema.v1.kinetic_forge_schema`
class MockAssetModel(BaseModel):
    id: str
    type: str = "base_asset"
    path: str

class MockGeometryModel(BaseModel):
    id: str
    type: str = "base_geometry"
    shape: str

class KineticForgeSchema(BaseModel):
    name: str
    version: str = "v1"
    assets: List[MockAssetModel] = Field(default_factory=list)
    geometries: List[MockGeometryModel] = Field(default_factory=list)

class MockKineticForgeSchemaModule:
    KineticForgeSchema = KineticForgeSchema
    MockAssetModel = MockAssetModel # Expose internal mocks if needed by other parts
    MockGeometryModel = MockGeometryModel

mock_kinetic_forge_schema_instance = MockKineticForgeSchemaModule()


# --- Mock PluginManager (this is the component being tested) ---
# This version uses the mocks defined above and interacts with sys.modules to simulate plugin loading.
class PluginManager:
    def __init__(self, plugin_paths: List[Path]):
        self.plugin_paths = plugin_paths
        self._loaded_plugin_modules: List[Any] = []
        self._original_sys_path: List[str] = sys.path[:] # Store original sys.path
        self._original_sys_modules: Dict[str, Any] = sys.modules.copy() # Store original sys.modules

    def _load_plugin_module(self, plugin_file: Path):
        module_name = f"kfs_plugin_{plugin_file.stem}" # Create a unique module name
        plugin_dir = str(plugin_file.parent)
        if plugin_dir not in sys.path:
            sys.path.insert(0, plugin_dir) # Add plugin directory to sys.path for imports

        spec = importlib.util.spec_from_file_location(module_name, plugin_file)
        if spec is None:
            raise ImportError(f"Could not load spec for plugin: {plugin_file}")
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module # Add module to sys.modules
        spec.loader.exec_module(module) # Execute plugin code
        self._loaded_plugin_modules.append(module)
        return module

    def load_plugins(self):
        mock_custom_types_instance.clear_custom_models_registry() # Clear registry before loading
        for plugin_path in self.plugin_paths:
            if not plugin_path.exists() or not plugin_path.is_dir():
                print(f"Plugin path does not exist or is not a directory: {plugin_path}")
                continue
            for plugin_file in plugin_path.glob("*.py"): # Iterate over Python files
                if plugin_file.name.startswith("_") or plugin_file.name.startswith("test_"):
                    continue # Skip __init__.py and test files
                try:
                    self._load_plugin_module(plugin_file)
                except Exception as e:
                    # In a real system, this would be logged. For tests, we print to debug.
                    print(f"Error loading plugin {plugin_file.name}: {e}")

    def apply_plugins(self, base_schema: Type[KineticForgeSchema]) -> Type[KineticForgeSchema]:
        registered_models = mock_custom_types_instance.get_registered_custom_models()
        if not registered_models:
            return base_schema # Return original schema if no custom types registered

        new_fields: Dict[str, Any] = {}
        for model_name, model_class in registered_models.items():
            # Convention: plugin adds a new top-level list field named after the model, lowercased, pluralized
            field_name = f"{model_name.lower()}s" # e.g., CustomPart -> customparts
            new_fields[field_name] = (List[model_class], Field(default_factory=list, description=f"Custom {model_name} components provided by a plugin."))

        extended_schema_name = f"{base_schema.__name__}ExtendedByPlugins"
        ExtendedSchema = create_model(
            extended_schema_name,
            __base__=base_schema,
            **new_fields,
            __module__=base_schema.__module__, # Associate new model with base schema's module
        )
        return ExtendedSchema

    def __enter__(self):
        # Temporarily place mock modules into sys.modules to simulate backend environment for plugins
        sys.modules["backend.kfs_manifest.extensibility.custom_types"] = mock_custom_types_instance
        sys.modules["backend.kfs_manifest.schema.v1.kinetic_forge_schema"] = mock_kinetic_forge_schema_instance
        sys.modules["backend.kfs_manifest.schema.v1.kinetic_forge_schema"].KineticForgeSchema = KineticForgeSchema # Ensure direct access to the base class
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        # Restore original sys.path
        sys.path = self._original_sys_path[:]
        # Clear custom models registry for test isolation
        mock_custom_types_instance.clear_custom_models_registry()
        # Clean up loaded plugin modules and restore modified sys.modules entries
        for module_name in list(sys.modules.keys()):
            if module_name.startswith("kfs_plugin_"):
                del sys.modules[module_name]
            if module_name in self._original_sys_modules:
                if sys.modules[module_name] is not self._original_sys_modules[module_name]: # Only restore if it was modified by us
                    sys.modules[module_name] = self._original_sys_modules[module_name]
            elif module_name in ["backend.kfs_manifest.extensibility.custom_types", "backend.kfs_manifest.schema.v1.kinetic_forge_schema"]:
                # If our mock was newly added and wasn't there originally, delete it
                if module_name not in self._original_sys_modules:
                    del sys.modules[module_name]

# --- Test Fixtures ---
@pytest.fixture
def plugin_dir():
    """Creates a temporary directory for plugins and cleans it up."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)

@pytest.fixture(autouse=True)
def mock_kfs_modules_fixture():
    """Ensures mock KFS modules are set up in sys.modules for each test and cleaned up."""
    # This fixture uses the global mock_custom_types_instance and mock_kinetic_forge_schema_instance
    # The PluginManager's context manager handles injecting and cleaning up these specific mocks in sys.modules.
    # This fixture mainly serves as a placeholder to ensure the global instances are reset if needed outside PluginManager's scope.
    yield mock_custom_types_instance # Provide the mock instance for direct assertions in tests
    mock_custom_types_instance.clear_custom_models_registry()


# --- Test Cases ---
def test_plugin_manager_loads_custom_type(plugin_dir: Path, mock_kfs_modules_fixture: MockCustomTypesModule):
    """Verify the plugin manager loads a custom type from a plugin file."""
    plugin_content = """
from pydantic import BaseModel
from backend.kfs_manifest.extensibility.custom_types import register_custom_model

class CustomPart(BaseModel):
    part_id: str
    material: str

register_custom_model("CustomPart", CustomPart)
    """
    plugin_file = plugin_dir / "my_custom_plugin.py"
    plugin_file.write_text(plugin_content)

    manager = PluginManager([plugin_dir])
    with manager: # Context manager handles sys.path and sys.modules setup/teardown
        manager.load_plugins()
        registered_models = mock_kfs_modules_fixture.get_registered_custom_models()
        assert "CustomPart" in registered_models
        assert issubclass(registered_models["CustomPart"], BaseModel)
        assert registered_models["CustomPart"].__name__ == "CustomPart"

def test_plugin_manager_applies_custom_type_to_schema(plugin_dir: Path, mock_kfs_modules_fixture: MockCustomTypesModule):
    """Verify that the plugin manager can apply custom types, extending the schema."""
    plugin_content = """
from pydantic import BaseModel
from backend.kfs_manifest.extensibility.custom_types import register_custom_model

class CustomFixture(BaseModel):
    fixture_id: str
    location: str

register_custom_model("CustomFixture", CustomFixture)
    """
    plugin_file = plugin_dir / "fixture_plugin.py"
    plugin_file.write_text(plugin_content)

    manager = PluginManager([plugin_dir])
    with manager:
        manager.load_plugins()
        ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema) # Use the base KineticForgeSchema from the test file

        # Check if the new field is present in the extended schema
        assert hasattr(ExtendedKineticForgeSchema, "model_fields")
        assert "customfixtures" in ExtendedKineticForgeSchema.model_fields
        assert ExtendedKineticForgeSchema.model_fields["customfixtures"].annotation == List[mock_kfs_modules_fixture.get_registered_custom_models()["CustomFixture"]]

        # Verify a basic instance can be created and validates
        manifest_data = {
            "name": "project_with_custom_fixture",
            "version": "v1",
            "customfixtures": [
                {"fixture_id": "FX001", "location": "A1"}
            ]
        }
        extended_schema_instance = ExtendedKineticForgeSchema(**manifest_data)
        assert extended_schema_instance.name == "project_with_custom_fixture"
        assert len(extended_schema_instance.customfixtures) == 1
        assert extended_schema_instance.customfixtures[0].fixture_id == "FX001"

def test_extended_schema_validation_success(plugin_dir: Path, mock_kfs_modules_fixture: MockCustomTypesModule):
    """Verify that an extended schema validates correctly with custom type data."""
    plugin_content = """
from pydantic import BaseModel
from backend.kfs_manifest.extensibility.custom_types import register_custom_model

class CustomTool(BaseModel):
    tool_name: str
    power_rating: float

register_custom_model("CustomTool", CustomTool)
    """
    plugin_file = plugin_dir / "tool_plugin.py"
    plugin_file.write_text(plugin_content)

    manager = PluginManager([plugin_dir])
    with manager:
        manager.load_plugins()
        ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)

        manifest_data = {
            "name": "project_with_custom_tool",
            "version": "v1",
            "assets": [
                {"id": "A1", "type": "motor", "path": "motors/motor.step"}
            ],
            "customtools": [
                {"tool_name": "DrillPress", "power_rating": 1.5},
                {"tool_name": "Lathe", "power_rating": 2.0}
            ]
        }
        try:
            extended_schema_instance = ExtendedKineticForgeSchema(**manifest_data)
            assert extended_schema_instance.name == "project_with_custom_tool"
            assert len(extended_schema_instance.assets) == 1
            assert len(extended_schema_instance.customtools) == 2
            assert extended_schema_instance.customtools[0].tool_name == "DrillPress"
        except ValidationError as e:
            pytest.fail(f"Validation failed unexpectedly: {e}")

def test_extended_schema_validation_failure(plugin_dir: Path, mock_kfs_modules_fixture: MockCustomTypesModule):
    """Verify that an extended schema correctly raises validation errors for invalid custom type data."""
    plugin_content = """
from pydantic import BaseModel
from backend.kfs_manifest.extensibility.custom_types import register_custom_model

class CustomSensor(BaseModel):
    sensor_id: str
    measurement_unit: str

register_custom_model("CustomSensor", CustomSensor)
    """
    plugin_file = plugin_dir / "sensor_plugin.py"
    plugin_file.write_text(plugin_content)

    manager = PluginManager([plugin_dir])
    with manager:
        manager.load_plugins()
        ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)

        manifest_data = {
            "name": "project_with_bad_sensor",
            "version": "v1",
            "customsensors": [
                {"sensor_id": "S001"} # Missing 'measurement_unit' field
            ]
        }
        with pytest.raises(ValidationError) as exc_info:
            ExtendedKineticForgeSchema(**manifest_data)

        assert "measurement_unit" in str(exc_info.value)
        assert "Field required" in str(exc_info.value)

def test_no_plugins_loaded(plugin_dir: Path):
    """Verify apply_plugins returns the base schema if no plugins are loaded."""
    manager = PluginManager([plugin_dir])
    with manager:
        manager.load_plugins() # No plugin files in dir
        ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)
        assert ExtendedKineticForgeSchema is KineticForgeSchema # Should return the original schema instance

def test_invalid_plugin_content_error_handling(plugin_dir: Path, mock_kfs_modules_fixture: MockCustomTypesModule):
    """Verify that plugin manager handles invalid plugin files gracefully (e.g., syntax error)."""
    plugin_content = """
from pydantic import BaseModel
from backend.kfs_manifest.extensibility.custom_types import register_custom_model

class BrokenPlugin(BaseModel: # Syntax error here
    name: str

register_custom_model("BrokenPlugin", BrokenPlugin)
    """
    plugin_file = plugin_dir / "broken_plugin.py"
    plugin_file.write_text(plugin_content)

    manager = PluginManager([plugin_dir])
    with manager:
        # load_plugins should catch the error during exec_module and not raise an unhandled exception.
        manager.load_plugins()
        assert "BrokenPlugin" not in mock_kfs_modules_fixture.get_registered_custom_models()
        ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)
        assert ExtendedKineticForgeSchema is KineticForgeSchema # No valid plugins loaded, so base schema is returned

def test_plugin_registers_non_basemodel(plugin_dir: Path, mock_kfs_modules_fixture: MockCustomTypesModule):
    """Verify that registering a non-BaseModel is handled (e.g., raises TypeError in mock)."""
    plugin_content = """
from backend.kfs_manifest.extensibility.custom_types import register_custom_model

class NotABaseModel:
    data: str

register_custom_model("NotABaseModel", NotABaseModel)
    """
    plugin_file = plugin_dir / "invalid_reg_plugin.py"
    plugin_file.write_text(plugin_content)

    manager = PluginManager([plugin_dir])
    with manager:
        # The mock_custom_types_instance.register_custom_model will raise TypeError which _load_plugin_module catches.
        manager.load_plugins()
        assert "NotABaseModel" not in mock_kfs_modules_fixture.get_registered_custom_models()
        ExtendedKineticForgeSchema = manager.apply_plugins(KineticForgeSchema)
        assert ExtendedKineticForgeSchema is KineticForgeSchema
