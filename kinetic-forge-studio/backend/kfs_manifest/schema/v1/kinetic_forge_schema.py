from typing import List, Optional
from pydantic import BaseModel, Field

from .asset_models import AssetModel
from .geometry_models import GeometryModel
from .motion_models import MotionModel


class KineticForgeSchema(BaseModel):
    """
    Represents the root of a .kfs.yaml file, combining asset, geometry,
    and motion models. This schema defines the overall structure and content
    of a KineticForge System manifest file.
    """
    schema_version: str = Field(
        ...,
        description="The version of the KineticForgeSchema being used. "
                    "Typically 'v1'."
    )
    assets: Optional[List[AssetModel]] = Field(
        None,
        description="A list of asset definitions that can be referenced by "
                    "geometry or other components."
    )
    geometry: Optional[List[GeometryModel]] = Field(
        None,
        description="A list of geometry definitions, specifying shapes and "
                    "visual properties."
    )
    motion: Optional[List[MotionModel]] = Field(
        None,
        description="A list of motion definitions, describing how components "
                    "move or interact."
    )

    class Config:
        schema_extra = {
            "examples": [
                {
                    "schema_version": "v1",
                    "assets": [
                        {
                            "id": "robot_arm_mesh",
                            "type": "mesh",
                            "uri": "kfs://meshes/robot_arm.glb",
                            "metadata": {
                                "creator": "KFS Team",
                                "version": "1.0",
                                "description": "3D model of a robot arm."
                            }
                        }
                    ],
                    "geometry": [
                        {
                            "id": "robot_base",
                            "type": "box",
                            "parameters": {
                                "width": 0.5,
                                "height": 0.2,
                                "depth": 0.5
                            },
                            "visual_properties": {
                                "color": [0.7, 0.7, 0.7, 1.0],
                                "material": "matte"
                            }
                        },
                        {
                            "id": "robot_link_1",
                            "type": "cylinder",
                            "parameters": {
                                "radius": 0.05,
                                "height": 0.3
                            },
                            "visual_properties": {
                                "color": [0.2, 0.8, 0.2, 1.0],
                                "material": "glossy"
                            },
                            "parent_asset_id": "robot_arm_mesh" # Example of linking to an asset
                        }
                    ],
                    "motion": [
                        {
                            "id": "shoulder_joint_motion",
                            "type": "revolute",
                            "target_component_id": "shoulder_joint",
                            "parameters": {
                                "axis": [0, 0, 1],
                                "limits": [-1.57, 1.57],
                                "initial_position": 0.0
                            },
                            "simulation_properties": {
                                "damping": 0.1,
                                "stiffness": 10.0
                            }
                        },
                        {
                            "id": "slider_actuator_motion",
                            "type": "prismatic",
                            "target_component_id": "slider_actuator",
                            "parameters": {
                                "axis": [1, 0, 0],
                                "limits": [0.0, 0.2],
                                "initial_position": 0.05
                            },
                            "simulation_properties": {
                                "damping": 0.05,
                                "stiffness": 50.0
                            }
                        }
                    ]
                }
            ]
        }
