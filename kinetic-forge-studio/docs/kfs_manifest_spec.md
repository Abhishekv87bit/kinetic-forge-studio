# KFS Manifest Specification (kfs.yaml)

## Introduction

The Kinetic Forge Studio (KFS) manifest (`.kfs.yaml` or `.kfs.json`) is a declarative
configuration file used to define kinetic sculpture projects. It specifies the 3D geometry,
materials, motion parameters, and simulation settings for a sculpture, enabling both
designers and automated tools to describe and interact with KFS projects.

This document provides a high-level overview of the manifest structure. For the definitive
and detailed technical specification, please refer to the [KFS JSON Schema](./kfs_v1.0.json).

## Manifest Structure

The KFS manifest is a YAML (or JSON) file with a root object containing several top-level fields:

```yaml
kfs_version: "1.0.0"
name: "My Awesome Kinetic Sculpture"
description: "A brief description of the project."
geometries: {}
materials: {}
objects: []
simulation_settings: {}
```

### `kfs_version` (Required)

-   **Type**: `string`
-   **Pattern**: `^\d+\.\d+\.\d+$` (e.g., "1.0.0")
-   **Description**: Specifies the version of the KFS manifest schema this file adheres to.
    The KFS parser will check for major version compatibility.

### `name` (Required)

-   **Type**: `string`
-   **Min Length**: 1
-   **Max Length**: 128
-   **Description**: A human-readable name for the kinetic sculpture project.

### `description` (Optional)

-   **Type**: `string` or `null`
-   **Description**: A brief, optional description of the project.

### `geometries` (Optional)

-   **Type**: `object`
-   **Description**: A dictionary (map) where keys are unique identifiers (strings) and values
    are reusable 3D geometry definitions. Objects in the `objects` list can then reference
    these definitions by their ID.
-   **Example Definition**:
    ```yaml
    geometries:
      sphere01:
        type: sphere
        id: sphere01
        radius: 1.5
      cubeA:
        type: cube
        id: cubeA
        size: 2.0
      customMesh:
        type: mesh
        id: customMesh
        path: "assets/models/detailed_part.obj"
    ```

### `materials` (Optional)

-   **Type**: `object`
-   **Description**: A dictionary (map) where keys are unique identifiers (strings) and values
    are reusable material definitions. Objects in the `objects` list can then reference
    these definitions by their ID.
-   **Example Definition**:
    ```yaml
    materials:
      redShiny:
        id: redShiny
        color: {r: 255, g: 0, b: 0}
        roughness: 0.2
        metallic: 0.8
      matteBlue:
        id: matteBlue
        color: {r: 0, g: 0, b: 255}
        roughness: 0.9
        metallic: 0.1
    ```

### `objects` (Required)

-   **Type**: `array`
-   **Min Items**: 1
-   **Description**: A list of `KFSObject` definitions, representing the individual kinetic
    elements in the sculpture. Each object specifies its geometry, material, initial transform,
    and optional animation.
-   **Example Definition**:
    ```yaml
    objects:
      - id: mainArm
        geometry_id: customMesh
        material_id: redShiny
        transform:
          position: [0, 0, 0]
          rotation: [0, 45, 0]
          scale: [1, 1, 1]
        animation: # Optional animation for this object
          tracks:
            - property: "rotation_y"
              keyframes:
                - time: 0.0
                  value: 0
                - time: 5.0
                  value: 360
              loop: true
    ```

### `simulation_settings` (Optional)

-   **Type**: `object`
-   **Description**: A dictionary for various simulation-specific parameters. This can include
    physics settings, time steps, rendering quality, and other configurable options for the KFS
    runtime. Its structure is flexible and can be extended by specific KFS implementations.

## Core Concepts

### Geometry Types

KFS supports several built-in geometry types and the ability to import external meshes:

-   `sphere`: Defined by a `radius`.
-   `cube`: Defined by a `size` (side length).
-   `mesh`: References an external 3D model file (e.g., `.obj`, `.gltf`) via a `path` URI.

### Material Properties

Materials define the visual appearance of objects:

-   `id`: Unique identifier.
-   `color`: An `RGBColor` object `{r: 0-255, g: 0-255, b: 0-255}`.
-   `roughness` (Optional): `float` from 0.0 to 1.0. 0.0 is perfectly smooth/mirror-like, 1.0 is completely matte.
-   `metallic` (Optional): `float` from 0.0 to 1.0. 0.0 is dielectric, 1.0 is purely metallic.
-   `emissive_color` (Optional): An `RGBColor` object for self-illumination.

### Transforms

Every `KFSObject` has a `transform` which defines its spatial properties:

-   `position`: A `Vector3` `[x, y, z]` representing the object's translation.
-   `rotation`: A `Vector3` `[x, y, z]` representing the object's rotation in degrees (Euler angles).
-   `scale`: A `Vector3` `[x, y, z]` representing the object's scaling.

### Animation

Animation is defined by a list of `AnimationTrack`s, where each track animates a specific property
of the object's `transform` over time using `Keyframe`s.

-   **`AnimationTrack`**: Contains:
    -   `property`: The name of the `transform` property to animate (e.g., `position_x`, `rotation_y`, `scale_z`).
    -   `keyframes`: A list of `Keyframe` objects.
    -   `loop`: Boolean, whether the track should loop.

-   **`Keyframe`**: Defines a point in time for an animation:
    -   `time`: Time in seconds.
    -   `value`: The value of the property at that time.
    -   `interpolation`: Method to interpolate to the next keyframe (`linear`, `smooth`, `step`).

## Validation

KFS manifests are validated against a JSON Schema to ensure structural correctness. Additionally,
semantic validation rules enforce logical consistency (e.g., referenced geometry/material IDs must exist).

---