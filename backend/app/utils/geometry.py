"""
Shared geometry generation utilities.

Single source of truth for converting component dicts into GeometryResult
objects. Used by viewport, validation, and export routes.
"""

from app.engines.geometry_engine import GeometryEngine, GeometryResult


def component_to_geometry(
    engine: GeometryEngine, comp: dict
) -> GeometryResult | None:
    """
    Generate a GeometryResult from a component dict.

    Args:
        engine: The GeometryEngine instance.
        comp: Component dict with keys: id, type, parameters.

    Returns:
        GeometryResult or None if component type is unrecognized.
    """
    ctype = comp.get("type", "")
    params = comp.get("parameters", {})
    if not isinstance(params, dict):
        params = {}
    name = comp.get("id", "part")

    if ctype == "gear":
        return engine.generate_gear(
            module=float(params.get("module", 1.5)),
            teeth=int(params.get("teeth", 20)),
            height=float(params.get("height", 8)),
            name=name,
        )
    elif ctype == "box":
        return engine.generate_box(
            length=float(params.get("length", 10)),
            width=float(params.get("width", 10)),
            height=float(params.get("height", 10)),
            name=name,
        )
    elif ctype == "cylinder":
        return engine.generate_cylinder(
            radius=float(params.get("radius", 5)),
            height=float(params.get("height", 10)),
            name=name,
        )
    elif ctype == "rack":
        return engine.generate_rack(
            module=float(params.get("module", 1.5)),
            num_teeth=int(params.get("num_teeth", 10)),
            height=float(params.get("height", 8)),
            body_height=float(params.get("body_height", 10)),
            name=name,
        )
    elif ctype == "sphere":
        return engine.generate_sphere(
            radius=float(params.get("radius", 5)),
            name=name,
        )
    elif ctype == "cone":
        return engine.generate_cone(
            bottom_radius=float(params.get("bottom_radius", 5)),
            top_radius=float(params.get("top_radius", 0)),
            height=float(params.get("height", 10)),
            name=name,
        )
    elif ctype == "torus":
        return engine.generate_torus(
            major_radius=float(params.get("major_radius", 10)),
            minor_radius=float(params.get("minor_radius", 2)),
            name=name,
        )
    elif ctype == "custom":
        # Custom type requires a mesh file path to load.
        # Not yet implemented — needs a load_mesh/import_mesh method on
        # GeometryEngine that can read STL/STEP from params["mesh_path"].
        return None
    return None
