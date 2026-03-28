# Kinetic Forge Studio (KFS) Manifest Schema (.kfs.yaml)

This document describes the structure and fields of the `.kfs.yaml` manifest file, which is used to define kinetic sculptures, their properties, motion, and simulation settings within Kinetic Forge Studio (KFS).

## Overview

A `.kfs.yaml` file is a YAML document that specifies a `KineticSculpture` resource. It follows a standard API object structure, including `apiVersion`, `kind`, `metadata`, and `spec`.

```yaml
apiVersion: kfs.kineticforge.studio/v1alpha1
kind: KineticSculpture
metadata:
  name: spinning-cube-display
  description: A simple kinetic sculpture with a rotating cube and a static base.
spec:
  # ... sculpture definition ...
```

## Top-Level Fields

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `apiVersion`  | `string` | The API version of the KFS manifest schema. Currently `kfs.kineticforge.studio/v1alpha1`. | Yes      |
| `kind`        | `string` | Denotes the type of the KFS resource. Must be `KineticSculpture`.    | Yes      |
| `metadata`    | `object` | Standard object metadata.                                            | Yes      |
| `spec`        | `object` | The specification for the KineticSculpture. This defines its geometry, materials, motion, and simulation settings. | Yes      |

## `metadata` Fields

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `name`        | `string` | A unique, human-readable name for the sculpture. Must be a valid DNS subdomain name (lowercase alphanumeric, `-`, `.` permitted, start/end with alphanumeric). | Yes      |
| `description` | `string` | A brief, human-readable description of the sculpture.                | No       |
| `tags`        | `array`  | Optional list of keywords for categorization (e.g., `["abstract", "mechanical"]`). | No       |

## `spec` Fields

This section defines the actual properties of the kinetic sculpture.

| Field              | Type      | Description                                                          | Required |
| :----------------- | :-------- | :------------------------------------------------------------------- | :------- |
| `components`       | `array`   | A list of individual sculptural components, each with its own geometry, material, and motion. | Yes      |
| `environment`      | `object`  | Defines global environment settings like lighting and background.    | No       |
| `simulation`       | `object`  | Defines global simulation parameters.                                | No       |

### `spec.components[]` (Sculpture Component)

Each object in the `components` array represents a distinct physical part of the sculpture.

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `name`        | `string` | A unique name for this component within the sculpture.               | Yes      |
| `geometry`    | `object` | Defines the shape and dimensions of the component.                   | Yes      |
| `material`    | `object` | Defines the visual properties (color, reflectivity) of the component. | Yes      |
| `motion`      | `object` | Defines the movement parameters for the component.                   | No       |
| `initialPosition` | `object` | Defines the initial position and rotation of the component.          | No       |

### `spec.components[].initialPosition`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `translation` | `array`  | `[x, y, z]` coordinates for the component's starting position. Default: `[0, 0, 0]`. | No       |
| `rotation`    | `array`  | `[x, y, z, angle]` for axis-angle rotation (radians). Default: `[0, 1, 0, 0]`. | No       |

### `spec.components[].geometry`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `type`        | `string` | The type of primitive geometry. Can be `Box`, `Sphere`, `Cylinder`, `Plane`, or `Mesh`. | Yes      |
| `parameters`  | `object` | Specific parameters for the chosen geometry type.                    | Yes      |

#### `geometry.parameters` for `type: Box`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `dimensions`  | `array`  | `[width, height, depth]` in KFS units.                               | Yes      |

#### `geometry.parameters` for `type: Sphere`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `radius`      | `number` | The radius of the sphere in KFS units.                               | Yes      |

#### `geometry.parameters` for `type: Cylinder`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `radius`      | `number` | The radius of the cylinder base in KFS units.                        | Yes      |
| `height`      | `number` | The height of the cylinder in KFS units.                             | Yes      |

#### `geometry.parameters` for `type: Plane`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `width`       | `number` | The width of the plane in KFS units.                                 | Yes      |
| `depth`       | `number` | The depth of the plane in KFS units.                                 | Yes      |

#### `geometry.parameters` for `type: Mesh`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `path`        | `string` | Path to the 3D model file (e.g., `.obj`, `.gltf`).                   | Yes      |
| `scale`       | `number` | Optional scaling factor to apply to the imported mesh. Default: `1.0`. | No       |

### `spec.components[].material`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `color`       | `string` | Hexadecimal color code (e.g., `"#FF0000"` for red) or standard CSS color name. | Yes      |
| `roughness`   | `number` | Roughness of the material, from `0.0` (smooth) to `1.0` (matte). Default: `0.5`. | No       |
| `metallic`    | `number` | Metallic property, from `0.0` (dielectric) to `1.0` (metal). Default: `0.0`. | No       |
| `opacity`     | `number` | Opacity of the material, from `0.0` (transparent) to `1.0` (opaque). Default: `1.0`. | No       |
| `emissive`    | `string` | Optional: Hexadecimal color code for self-illumination. Default: `"#000000"`. | No       |

### `spec.components[].motion`

Defines how a component moves over time. Multiple motion definitions can be chained or executed concurrently.

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `type`        | `string` | The type of motion. Can be `Rotate`, `Translate`, `Scale`, `Keyframe`, `Script`. | Yes      |
| `parameters`  | `object` | Specific parameters for the chosen motion type.                      | Yes      |
| `duration`    | `number` | How long the motion takes in seconds. Default: `0` (instantaneous for some types). | No       |
| `delay`       | `number` | Delay before the motion starts, in seconds. Default: `0`.            | No       |
| `loop`        | `boolean`| If `true`, the motion will repeat indefinitely. Default: `false`.    | No       |
| `easing`      | `string` | Easing function (e.g., `linear`, `easeInQuad`, `easeOutCubic`). Default: `linear`. | No       |

#### `motion.parameters` for `type: Rotate`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `axis`        | `array`  | `[x, y, z]` vector defining the axis of rotation.                    | Yes      |
| `speed`       | `number` | Rotational speed in radians per second. Positive for clockwise, negative for counter-clockwise. | Yes      |
| `origin`      | `array`  | `[x, y, z]` point around which to rotate (local to component). Default: `[0, 0, 0]`. | No       |

#### `motion.parameters` for `type: Translate`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `path`        | `array`  | List of `[x, y, z]` points the component should follow. The motion will interpolate between these points. | Yes      |
| `relative`    | `boolean`| If `true`, points are relative to the component's current position. Default: `false`. | No       |

#### `motion.parameters` for `type: Scale`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `factor`      | `array`  | `[sx, sy, sz]` scaling factors to apply.                             | Yes      |
| `origin`      | `array`  | `[x, y, z]` point around which to scale (local to component). Default: `[0, 0, 0]`. | No       |

#### `motion.parameters` for `type: Keyframe`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `keyframes`   | `array`  | List of keyframe objects.                                            | Yes      |

##### `keyframes[]` object

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `time`        | `number` | Time in seconds relative to the start of this motion sequence.       | Yes      |
| `translation` | `array`  | `[x, y, z]` position at this keyframe.                               | No       |
| `rotation`    | `array`  | `[x, y, z, angle]` axis-angle rotation at this keyframe (radians).   | No       |
| `scale`       | `array`  | `[sx, sy, sz]` scale at this keyframe.                               | No       |

#### `motion.parameters` for `type: Script`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `path`        | `string` | Path to an external KFS motion script (e.g., Python, Lua).           | Yes      |
| `language`    | `string` | The scripting language (e.g., `python`, `lua`).                      | No       |
| `args`        | `object` | Optional key-value pairs to pass as arguments to the script.         | No       |

### `spec.environment`

Global settings for the simulation environment.

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `lighting`    | `object` | Defines global lighting conditions.                                  | No       |
| `background`  | `object` | Defines the background of the scene.                                 | No       |

#### `environment.lighting`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `type`        | `string` | Type of lighting: `Ambient`, `Directional`, `Point`.                 | Yes      |
| `color`       | `string` | Hexadecimal color code of the light. Default: `"#FFFFFF"`.           | No       |
| `intensity`   | `number` | Brightness of the light. Default: `1.0`.                             | No       |
| `direction`   | `array`  | `[x, y, z]` vector for `Directional` light.                          | Conditional |
| `position`    | `array`  | `[x, y, z]` position for `Point` light.                              | Conditional |

#### `environment.background`

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `type`        | `string` | Type of background: `Color`, `Image`, `Skybox`.                      | Yes      |
| `color`       | `string` | Hexadecimal color code for `Color` type.                             | Conditional |
| `path`        | `string` | Path to image file for `Image` or `Skybox` types.                    | Conditional |

### `spec.simulation`

Global settings for the simulation engine.

| Field         | Type     | Description                                                          | Required |
| :------------ | :------- | :------------------------------------------------------------------- | :------- |
| `duration`    | `number` | Total simulation duration in seconds. Default: `60`.                 | No       |
| `gravity`     | `array`  | `[x, y, z]` vector defining gravitational force. Default: `[0, -9.81, 0]`. | No       |
| `fps`         | `integer`| Frames per second for the simulation export/rendering. Default: `60`.| No       |
| `collisionDetection`| `boolean`| Enable or disable physical collision detection. Default: `true`.   | No       |
