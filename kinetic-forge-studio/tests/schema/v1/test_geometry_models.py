import pytest
from pydantic import ValidationError

from backend.kfs_manifest.schema.v1.asset_models import AssetRef
from backend.kfs_manifest.schema.v1.geometry_models import (
    GeometryModel,
    MeshGeometry,
    BoxGeometry,
    CylinderGeometry,
    SphereGeometry,
    CapsuleGeometry,
    PlaneGeometry,
    HeightmapGeometry,
)


def test_geometry_model_abstract():
    """Test that GeometryModel (abstract base class) cannot be instantiated directly."""
    with pytest.raises(TypeError, match="Cannot instantiate abstract class GeometryModel"):
        GeometryModel()


def test_mesh_geometry_valid():
    """Test valid instantiation of MeshGeometry."""
    mesh = MeshGeometry(filename=AssetRef(path="models/test.obj"))
    assert mesh.filename.path == "models/test.obj"
    assert mesh.scale == [1.0, 1.0, 1.0]  # Default
    assert mesh.up_axis == "y"  # Default
    assert mesh.forward_axis == "x"  # Default

    mesh_custom = MeshGeometry(
        filename=AssetRef(path="models/custom.stl"),
        scale=[2.0, 2.0, 2.0],
        up_axis="z",
        forward_axis="y",
    )
    assert mesh_custom.filename.path == "models/custom.stl"
    assert mesh_custom.scale == [2.0, 2.0, 2.0]
    assert mesh_custom.up_axis == "z"
    assert mesh_custom.forward_axis == "y"


def test_mesh_geometry_invalid_filename():
    """Test invalid filename for MeshGeometry."""
    with pytest.raises(ValidationError, match="field required"):
        MeshGeometry()  # Missing filename
    with pytest.raises(ValidationError, match="Input should be a valid dictionary"):
        MeshGeometry(filename="invalid_string")  # Not an AssetRef type
    with pytest.raises(ValidationError, match="Input should be a valid dictionary"):
        MeshGeometry(filename={})  # Not an AssetRef type


def test_mesh_geometry_invalid_scale():
    """Test invalid scale for MeshGeometry."""
    with pytest.raises(ValidationError, match="List should have at most 3 items after validation, not 2"):
        MeshGeometry(filename=AssetRef(path="test.obj"), scale=[1.0, 2.0])  # Must be 3 elements
    with pytest.raises(ValidationError, match="Input should be a valid number"):
        MeshGeometry(filename=AssetRef(path="test.obj"), scale=[1, "a", 3])  # Must be floats


def test_mesh_geometry_invalid_axes():
    """Test invalid up_axis and forward_axis for MeshGeometry."""
    with pytest.raises(ValidationError, match="Input should be 'x', 'y' or 'z'"):
        MeshGeometry(filename=AssetRef(path="test.obj"), up_axis="invalid")
    with pytest.raises(ValidationError, match="Input should be 'x', 'y' or 'z'"):
        MeshGeometry(filename=AssetRef(path="test.obj"), forward_axis="invalid")


def test_box_geometry_valid():
    """Test valid instantiation of BoxGeometry."""pydantic v2 has slightly different error messages for list length validation.
    box = BoxGeometry(size=[1.0, 2.0, 3.0])
    assert box.size == [1.0, 2.0, 3.0]


def test_box_geometry_invalid_size():
    """Test invalid size for BoxGeometry."""
    with pytest.raises(ValidationError, match="field required"):
        BoxGeometry()  # Missing size
    with pytest.raises(ValidationError, match="List should have at most 3 items after validation, not 2"):
        BoxGeometry(size=[1.0, 2.0])  # Must be 3 elements
    with pytest.raises(ValidationError, match="Input should be a valid number"):
        BoxGeometry(size=[1, "a", 3])  # Must be floats


def test_cylinder_geometry_valid():
    """Test valid instantiation of CylinderGeometry."""
    cylinder = CylinderGeometry(radius=0.5, length=1.0)
    assert cylinder.radius == 0.5
    assert cylinder.length == 1.0


def test_cylinder_geometry_invalid_params():
    """Test invalid parameters for CylinderGeometry."""
    with pytest.raises(ValidationError, match="field required"):
        CylinderGeometry(radius=0.5)  # Missing length
    with pytest.raises(ValidationError, match="field required"):
        CylinderGeometry(length=1.0)  # Missing radius
    with pytest.raises(ValidationError, match="Input should be greater than 0"):
        CylinderGeometry(radius=-0.5, length=1.0)  # Negative radius
    with pytest.raises(ValidationError, match="Input should be greater than 0"):
        CylinderGeometry(radius=0.5, length=-1.0)  # Negative length


def test_sphere_geometry_valid():
    """Test valid instantiation of SphereGeometry."""
    sphere = SphereGeometry(radius=1.5)
    assert sphere.radius == 1.5


def test_sphere_geometry_invalid_radius():
    """Test invalid radius for SphereGeometry."""
    with pytest.raises(ValidationError, match="field required"):
        SphereGeometry()  # Missing radius
    with pytest.raises(ValidationError, match="Input should be greater than 0"):
        SphereGeometry(radius=-1.0)  # Negative radius


def test_capsule_geometry_valid():
    """Test valid instantiation of CapsuleGeometry."""
    capsule = CapsuleGeometry(radius=0.2, length=0.8)
    assert capsule.radius == 0.2
    assert capsule.length == 0.8


def test_capsule_geometry_invalid_params():
    """Test invalid parameters for CapsuleGeometry."""
    with pytest.raises(ValidationError, match="field required"):
        CapsuleGeometry(radius=0.2)  # Missing length
    with pytest.raises(ValidationError, match="field required"):
        CapsuleGeometry(length=0.8)  # Missing radius
    with pytest.raises(ValidationError, match="Input should be greater than 0"):
        CapsuleGeometry(radius=-0.1, length=0.8)  # Negative radius
    with pytest.raises(ValidationError, match="Input should be greater than 0"):
        CapsuleGeometry(radius=0.2, length=-0.8)  # Negative length


def test_plane_geometry_valid():
    """Test valid instantiation of PlaneGeometry."""
    plane = PlaneGeometry(size=[5.0, 5.0])
    assert plane.size == [5.0, 5.0]


def test_plane_geometry_invalid_size():
    """Test invalid size for PlaneGeometry."""
    with pytest.raises(ValidationError, match="field required"):
        PlaneGeometry()  # Missing size
    with pytest.raises(ValidationError, match="List should have at most 2 items after validation, not 3"):
        PlaneGeometry(size=[1.0, 2.0, 3.0])  # Must be 2 elements
    with pytest.raises(ValidationError, match="Input should be a valid number"):
        PlaneGeometry(size=[1, "a"])  # Must be floats


def test_heightmap_geometry_valid():
    """Test valid instantiation of HeightmapGeometry."""
    heightmap = HeightmapGeometry(
        filename=AssetRef(path="maps/height.png"), width=10.0, length=10.0, height=5.0
    )
    assert heightmap.filename.path == "maps/height.png"
    assert heightmap.width == 10.0
    assert heightmap.length == 10.0
    assert heightmap.height == 5.0
    assert heightmap.width_segments == 1  # Default
    assert heightmap.length_segments == 1  # Default

    heightmap_custom = HeightmapGeometry(
        filename=AssetRef(path="maps/height_hires.png"),
        width=20.0,
        length=20.0,
        height=10.0,
        width_segments=10,
        length_segments=10,
    )
    assert heightmap_custom.width_segments == 10
    assert heightmap_custom.length_segments == 10


def test_heightmap_geometry_invalid_filename():
    """Test invalid filename for HeightmapGeometry."""
    with pytest.raises(ValidationError, match="field required"):
        HeightmapGeometry(width=1.0, length=1.0, height=1.0)  # Missing filename


def test_heightmap_geometry_invalid_dimensions():
    """Test invalid dimensions for HeightmapGeometry."""
    with pytest.raises(ValidationError, match="field required"):
        HeightmapGeometry(filename=AssetRef(path="map.png"), length=1.0, height=1.0)  # Missing width
    with pytest.raises(ValidationError, match="field required"):
        HeightmapGeometry(filename=AssetRef(path="map.png"), width=1.0, height=1.0)  # Missing length
    with pytest.raises(ValidationError, match="field required"):
        HeightmapGeometry(filename=AssetRef(path="map.png"), width=1.0, length=1.0)  # Missing height
    with pytest.raises(ValidationError, match="Input should be greater than 0"):
        HeightmapGeometry(
            filename=AssetRef(path="map.png"), width=-1.0, length=1.0, height=1.0
        )  # Negative width
    with pytest.raises(ValidationError, match="Input should be greater than 0"):
        HeightmapGeometry(
            filename=AssetRef(path="map.png"), width=1.0, length=-1.0, height=1.0
        )  # Negative length
    with pytest.raises(ValidationError, match="Input should be greater than 0"):
        HeightmapGeometry(
            filename=AssetRef(path="map.png"), width=1.0, length=1.0, height=-1.0
        )  # Negative height


def test_heightmap_geometry_invalid_segments():
    """Test invalid segment counts for HeightmapGeometry."""
    with pytest.raises(ValidationError, match="Input should be greater than or equal to 1"):
        HeightmapGeometry(
            filename=AssetRef(path="map.png"),
            width=1.0,
            length=1.0,
            height=1.0,
            width_segments=0,
        )  # Must be >= 1
    with pytest.raises(ValidationError, match="Input should be greater than or equal to 1"):
        HeightmapGeometry(
            filename=AssetRef(path="map.png"),
            width=1.0,
            length=1.0,
            height=1.0,
            length_segments=-1,
        )  # Must be >= 1
    with pytest.raises(ValidationError, match="Input should be a valid integer"):
        HeightmapGeometry(
            filename=AssetRef(path="map.png"),
            width=1.0,
            length=1.0,
            height=1.0,
            width_segments=1.5,
        )  # Must be int
