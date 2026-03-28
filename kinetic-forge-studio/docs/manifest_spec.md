# Kinetic Forge Studio (.kfs.yaml) Manifest Specification

This document outlines the structure and required fields for a `.kfs.yaml` manifest file, which is used to define kinetic sculptures within Kinetic Forge Studio.

## Root Structure

A `.kfs.yaml` file must contain the following top-level keys:

- `version` (string): The schema version this manifest adheres to. Currently, this should be `"1.0"`.
- `metadata` (object): General information about the sculpture.
- `geometries` (array of objects): Definitions for reusable 3D geometries.
- `materials` (array of objects): Definitions for reusable visual materials.
- `objects` (array of objects): The actual physical or visual components of the sculpture.
- `animations` (array of objects): (Placeholder for future animation definitions, currently an empty list).
- `simulations` (object): Parameters for physics simulation.

---

## 1. `metadata`

Provides descriptive information about the kinetic sculpture.

| Field       | Type   | Description                                           |
| :---------- | :----- | :---------------------------------------------------- |
| `name`      | string | A human-readable name for the sculpture.              |
| `description` | string | A brief description of the sculpture's design or purpose. |

**Example:**

```yaml
metadata:
  name: "Rotating Cube Sculpture"
  description: "A simple kinetic sculpture featuring a rotating cube."
```

---

## 2. `geometries`

An array defining reusable 3D shapes. Each geometry must have a unique `name` and a `type` specifying its shape.

### Common Geometry Fields

| Field  | Type   | Description                                                        |
| :----- | :----- | :----------------------------------------------------------------- |
| `name` | string | A unique identifier for this geometry definition.                  |
| `type` | string | The specific type of geometry (e.g., `"box"`, `"sphere"`, `"cylinder"`, `"mesh"`). |

### `BoxGeometry` (`type: "box"`)

A rectangular prism.

| Field    | Type          | Description                                    |
| :------- | :------------ | :--------------------------------------------- |
| `width`  | positive float | Width of the box along the X-axis (must be positive). |
| `height` | positive float | Height of the box along the Y-axis (must be positive). |
| `depth`  | positive float | Depth of the box along the Z-axis (must be positive). |

**Example:**

```yaml
geometries:
  - name: "cube_geometry"
    type: "box"
    width: 1.0
    height: 1.0
    depth: 1.0
```

### `SphereGeometry` (`type: "sphere"`)

A sphere.

| Field    | Type          | Description                               |
| :------- | :------------ | :---------------------------------------- |
| `radius` | positive float | Radius of the sphere (must be positive). |

**Example:**

```yaml
geometries:
  - name: "ball_geometry"
    type: "sphere"
    radius: 0.5
```

---

## 3. `materials`

An array defining reusable visual materials. Each material must have a unique `name` and a `type`.

### Common Material Fields

| Field  | Type   | Description                                        |
| :----- | :----- | :------------------------------------------------- |
| `name` | string | A unique identifier for this material definition.  |
| `type` | string | The specific type of material (e.g., `"phong"`). |

### `PhongMaterial` (`type: "phong"`)

A common material model for reflecting light.

| Field   | Type   | Description                                                      |
| :------ | :----- | :--------------------------------------------------------------- |
| `color` | string | The base color of the material, typically a hex color string (e.g., `"#RRGGBB"`). |

**Example:**

```yaml
materials:
  - name: "red_plastic"
    type: "phong"
    color: "#FF0000"
```

---

## 4. `objects`

An array defining the physical components of the sculpture. Each object references a defined geometry and material.

| Field           | Type     | Description                                                     |
| :-------------- | :------- | :-------------------------------------------------------------- |
| `name`          | string   | A unique identifier for this object instance.                   |
| `type`          | string   | The type of object (e.g., `"rigid_body"`, `"static_body"`). |
| `transform`     | object   | The object's local position, rotation, and scale. See `Transform` below. |
| `geometry_ref`  | string   | The `name` of a geometry defined in the `geometries` section.   |
| `material_ref`  | string   | The `name` of a material defined in the `materials` section.    |

**Example:**

```yaml
objects:
  - name: "main_cube"
    type: "rigid_body"
    transform:
      position: {x: 0, y: 0, z: 0}
      rotation: {x: 0, y: 0, z: 0, w: 1} # Identity quaternion
      scale: {x: 1, y: 1, z: 1}
    geometry_ref: "cube_geometry"
    material_ref: "red_plastic"
```

### `Transform`

Defines an object's spatial properties.

| Field      | Type   | Description                                   |
| :--------- | :----- | :-------------------------------------------- |
| `position` | object | Local position (x, y, z). See `Vector3` below. |
| `rotation` | object | Local rotation as a quaternion (x, y, z, w). See `Quaternion` below. |
| `scale`    | object | Local scale factors (x, y, z). See `Vector3` below. |

---

### `Vector3`

A 3D vector or point.

| Field | Type  | Description |
| :---- | :---- | :---------- |
| `x`   | float | X component. |
| `y`   | float | Y component. |
| `z`   | float | Z component. |

**Example:** `{x: 1.0, y: 2.0, z: 3.0}`

---

### `Quaternion`

A 3D rotation.

| Field | Type  | Description |
| :---- | :---- | :---------- |
| `x`   | float | X component. |
| `y`   | float | Y component. |
| `z`   | float | Z component. |
| `w`   | float | W component. |

**Example:** `{x: 0.0, y: 0.707, z: 0.0, w: 0.707}` (90-degree rotation around Y axis)

---

## 5. `animations`

(Placeholder for future animation definitions.) Currently, an empty list is expected.

**Example:**

```yaml
animations: []
```

---

## 6. `simulations`

Parameters for the physics simulation engine.

| Field      | Type          | Description                                               |
| :--------- | :------------ | :-------------------------------------------------------- |
| `gravity`  | object        | The global gravity vector (x, y, z). See `Vector3` below. |
| `solver`   | string        | The physics solver to use (e.g., `"euler"`, `"rk4"`).   |
| `timestep` | positive float | The fixed time step for simulation updates (must be positive). |

**Example:**

```yaml
simulations:
  gravity: {x: 0, y: -9.81, z: 0}
  solver: "euler"
  timestep: 0.01
```
