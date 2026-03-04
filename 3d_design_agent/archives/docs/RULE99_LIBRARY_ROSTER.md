# Rule 99 — Complete Library Roster

Reference catalog for the Rule 99 Production Consultant Pipeline.
~95 libraries organized by phase and consultant role.

**Read on demand** — Claude references this when Rule 99 triggers to select the right tools.

---

## PHASE 1: DESIGN (Active During OpenSCAD)

### Kinematics & Mechanism

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| SymPy | `pip install sympy` | Solve linkage equations algebraically, derive exact cam profiles |
| SymPy.physics.mechanics | (included in SymPy) | Lagrangian/Kane's method for equations of motion |
| SciPy | `pip install scipy` | CubicSpline cam smoothing, jerk minimization, optimization |
| NumPy | `pip install numpy` | Phase offset arrays, wave grids, matrix operations |
| Pyslvs | github.com/KmolYuan/Pyslvs-UI | Linkage mechanism synthesis — finds dimensions for target motion path |
| pylinkage | github.com/HuMusic/pylinkage | Pure Python linkage simulation + optimization |
| pydy | github.com/pydy/pydy | Multibody dynamics — symbolic equations of motion |
| DynPy | github.com/bogumilchilinski/dynpy | Mass-spring-damper system modeling with predefined elements |
| NetworkX | `pip install networkx` | Linkage connectivity graphs, locking position detection |
| easing-functions | `pip install easing-functions` | Non-linear motion profiles (ease-in, bounce, elastic) |
| Ruckig | github.com/pantor/ruckig | Jerk-limited S-curve trajectories for motor control |

### Structural & Forces

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| PyNite | github.com/JWock82/PyNite | 3D frame analysis — deflection, stress, reactions |
| anastruct | github.com/ritchie46/anastruct | 2D frame/truss analysis (faster than PyNite for 2D) |
| sectionproperties | github.com/robbievanleeuwen/section-properties | Cross-section Ixx, Iyy, weight, plastic section modulus |
| FEniCS | fenicsproject.org | Advanced FEA for complex stress, topology optimization |
| SfePy | sfepy.org | Full FEA with OpenSCAD->Gmsh integration |

### Mass, Inertia & Balance

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| Trimesh | `pip install trimesh` | Mass properties, center of mass, moment of inertia from mesh + density |

### Fit, Clearance & Tolerance

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| dimstack | github.com/phcreery/dimstack | Tolerance stackup (worst-case + RSS + Monte Carlo) |
| stackups | `pip install stackups` | Six-sigma clearance verification |
| tol-stack | github.com/slightlynybbled/tol-stack | Monte Carlo tolerance analysis |
| Statistical Tolerance Analysis | github.com/EinmalmitProfis/Statistical-Tolerance-Analysis-and-Synthesis-with-Python | GPU-accelerated Monte Carlo (NumPy/CuPy) |
| iso286_lookup.py | CUSTOM (to build) | ISO 286 shaft/hole fit tolerances per nominal diameter |
| pint | `pip install pint` | Physical units — catches mm/inch, N/lbf errors |
| forallpeople | `pip install forallpeople` | SI units for engineering calculations |

### Materials & Corrosion

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| pymatgen | `pip install pymatgen` | Materials database, Pourbaix diagrams for galvanic corrosion |
| Thermo | `pip install thermo` | Thermal expansion coefficients, material property lookup |
| CoolProp | `pip install CoolProp` | Thermophysical properties at temperature |
| galvanic_matrix.py | CUSTOM (to build) | Quick corrosion risk check for material pairs (MIL-STD-889) |

### Drive System

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| gearpy | `pip install gearpy` | Gear train torque flow, speed ratios |
| cq_gears | github.com/meadiode/cq_gears | Gear profile generation (spur, helical, herringbone) |
| python-gearbox | github.com/kiskacompany/python-gearbox | Gear design per ISO 6336 / AGMA 2101 |
| freecad.gears | github.com/looooo/freecad.gears | Gear generation in FreeCAD |
| cq-warehouse | github.com/gumyr/cq-warehouse | Fastener logic, grip length calculation |
| BAT | github.com/misams/BAT | Bolt preload, torque, slippage analysis |
| ezbolt | github.com/wcfrobert/ezbolt | Bolt group force distribution |
| Springcalc | github.com/icyd/Springcalc | Spring characteristics from dimensions |

### Collision & Interference

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| python-fcl | github.com/BerkeleyAutomation/python-fcl | Moving part collision detection with clearance buffer |
| Trimesh | (boolean operations) | Mesh intersection for interference detection |

### Cables & Strings

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| pycatenary | github.com/tridelat/pycatenary | Cable sag, tension, catenary equation solver |

### Vibration

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| vibration_toolbox | vibrationtoolbox.github.io | Natural frequency analysis — resonance warnings |
| OpenTorsion | (ScienceDirect, Dec 2024) | Shaft torsional vibration |
| ROSS | github.com/petrobras/ross | Rotordynamic analysis — critical speeds, Campbell diagrams |
| pyFRF | github.com/ladisk/pyFRF | Frequency response from measured vibration data |
| sdypy | github.com/ladisk/sdypy | Structural dynamics suite |

### Aesthetics & Generative

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| noise | `pip install noise` | Perlin noise — organic variation for repetitive elements |
| SciPy.spatial.Voronoi | (included in SciPy) | Cell structures, organic patterns |
| TopOpt / topy | github.com/williamhunter/topy | Topology optimization — lightweight "alien bone" shapes |
| JAX / autograd | `pip install jax` | Differentiable physics for compliant mechanism design |
| sdf | github.com/fogleman/sdf | Signed distance function modeling — organic mathematical forms |

### Optimization

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| pymoo | github.com/anyoptimization/pymoo | Multi-objective optimization (weight vs stiffness vs cost) |
| pyomo | `pip install pyomo` | Constrained optimization (LP, NLP, MILP) |
| DEAP | `pip install deap` | Genetic algorithms — evolve mechanism designs |
| OpenMDAO | github.com/OpenMDAO/OpenMDAO | NASA multidisciplinary design optimization |

### Spatial Math

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| spatialmath-python | github.com/petercorke/spatialmath-python | Rigorous 3D transforms (SE3, quaternions, twists) |
| ikpy | `pip install ikpy` | Inverse kinematics for serial kinematic chains |
| roboticstoolbox-python | github.com/petercorke/robotics-toolbox-python | Forward/inverse kinematics, dynamics, trajectory |

---

## PHASE 2: PROTOTYPING (3D Print)

### Mesh Processing

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| pymeshfix | `pip install pymeshfix` | Fix holes, self-intersections, non-manifold edges |
| PyMeshLab | github.com/cnr-isti-vclab/PyMeshLab | 200+ mesh filters — repair, simplify, smooth |
| MeshLib | meshlib.io | Advanced mesh healing, tolerance-based repair |
| admesh | `pip install admesh` | Lightweight STL repair |
| numpy-stl | `pip install numpy-stl` | Fast STL read/write/transform |

### Tolerance Compensation

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| Trimesh | offset_surface | Shrink/grow mesh by printer tolerance |
| Shapely | buffer() | 2D elephant's foot compensation |

### Slicing & Printing

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| FullControl | github.com/FullControlXYZ/fullcontrol | Non-planar printing, stress-line following |
| SciSlice | github.com/VanHulleOne/SciSlice | Fine parameter control, tolerance compensation |
| SolidPython2 | github.com/jeff-dh/SolidPython | Generate OpenSCAD from Python syntax |

### Print-Specific Design

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| cq_gears | (herringbone profiles) | Self-aligning gears for FDM |
| python-fcl | (collision with buffer) | Print-in-place interference check |
| JAX/autograd | (topology optimization) | Compliant mechanism / flexure design |

---

## PHASE 3: PRODUCTION (Metal / Wood)

### CAD & Drawing Generation

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| CadQuery | github.com/CadQuery/cadquery | Parametric STEP file generation from Python |
| Build123d | github.com/gumyr/build123d | Modern Python CAD API, direct STEP export |
| cadscript | `pip install cadscript` | Simplified CadQuery API (feels like OpenSCAD, outputs STEP) |
| PythonOCC | github.com/tpaviot/pythonocc-core | Direct OpenCASCADE kernel access — advanced B-rep ops |
| FreeCAD TechDraw | (scripted via Python) | Auto-generate production drawings |
| FreeCAD-GDT | github.com/juanvanyo/FreeCAD-GDT | GD&T annotation per ISO 16792 |
| handcalcs | github.com/connorferster/handcalcs | Engineering calculation reports (LaTeX-formatted) |
| efficalc | `pip install efficalc` | Professional PDF calculation reports |
| mechplot | github.com/jorgepiloto/mechplot | Publication-quality mechanism diagrams |

### DXF / SVG / STEP File Manipulation

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| EzDXF | github.com/mozman/ezdxf | DXF with layers (CUT_RED, ETCH_BLUE), tabs |
| svgpathtools | github.com/mathandy/svgpathtools | Parse, transform, boolean SVG paths |
| svg2gcode | `pip install svg2gcode` | SVG -> G-code for CNC/laser |
| steputils | `pip install steputils` | Programmatic STEP file manipulation |
| meshio | `pip install meshio` | Universal mesh format converter |
| svgwrite | `pip install svgwrite` | Create SVG files programmatically |

### Nesting & Sheet Optimization

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| nest2D | `pip install nest2D` | Irregular shape nesting with rotation |
| DeepNest | github.com/Jack000/Deepnest | AI-based 2D nesting for laser/waterjet |
| rectpack | `pip install rectpack` | Rectangle bin packing (simpler parts) |

### CNC & G-code

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| pygcode | `pip install pygcode` | Parse and manipulate G-code |
| pycam | pycam.sourceforge.io | 3-axis CNC toolpath generation from STL/DXF |
| mecode | github.com/jminardi/mecode | Programmatic G-code with Python control flow |

### Fatigue & Lifetime

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| py-fatigue | github.com/OWI-Lab/py_fatigue | S-N curves, Paris' law, crack growth, cycle counting |
| fatpack | github.com/gunnstein/fatpack | Rainflow counting, Palmgren-Miner damage rule |
| pylife | github.com/boschresearch/pylife | Industrial fatigue assessment (Bosch) |
| sncurves | github.com/iamlikeme/sncurves | DNV S-N curves for welded joints |

### Reliability & Bearing Life

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| reliability | `pip install reliability` | Weibull analysis, L10->MTBF, survival curves |
| surpyval | `pip install surpyval` | Survival analysis from test data |

### Costing & BOM

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| Shapely | (perimeter calc) | Cut length for waterjet/laser pricing |
| InvenTree | github.com/inventree/inventree-python | Parts inventory and BOM management |
| openpyxl | `pip install openpyxl` | Generate BOM spreadsheets |
| tabulate | `pip install tabulate` | Formatted BOM tables |

### Acoustics & Noise

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| MOSQITO | github.com/Eomys/MoSQITo | Psychoacoustic metrics — loudness, sharpness, roughness |
| python-acoustics | github.com/python-acoustics/python-acoustics | Sound levels, noise standards (ISO 1996) |
| acoular | `pip install acoular` | Acoustic beamforming — locate noise sources |

### Sheet Metal & Welding (Custom)

| Script | Purpose | Formula Source |
|---|---|---|
| kfactor_calc.py | Bend allowance: BA = pi(R+KT)theta/180 | Industry K-factor tables |
| weld_sizer.py | Fillet/butt weld sizing per load | AWS D1.1 |
| finish_spec.py | Coating recommendation (material + environment) | Decision tree |

### Wear & Tribology

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| tribology | `pip install tribology` | Hertzian contact, EHL film thickness, friction, wear |

---

## PHASE 4: INSTALLED SCULPTURE

### IoT & Monitoring

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| PySerial | `pip install pyserial` | Serial communication with Arduino/ESP32 |
| paho-mqtt | `pip install paho-mqtt` | MQTT for sensor data pipeline |
| enDAQ | `pip install endaq` | Shock & vibration analysis from sensors |

### Motor & Control

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| ODrive | `pip install odrive` | High-performance BLDC motor control |
| pymodbus | `pip install pymodbus` | Industrial motor drive communication (Modbus) |
| python-osc | `pip install python-osc` | OSC protocol for TouchDesigner/Max/MSP |
| python-rtmidi | `pip install python-rtmidi` | MIDI control — sync to music |
| python-can | `pip install python-can` | CAN bus for industrial controllers |
| gpiozero | `pip install gpiozero` | Raspberry Pi GPIO for sensors/actuators |

### Visualization & AR

| Library | PyPI / GitHub | Consultant Role |
|---|---|---|
| PyVista | `pip install pyvista` | 3D visualization of thousands of moving points |
| VPython | `pip install vpython` | Physics-based string/weight simulation |
| k3d | `pip install k3d` | GPU-accelerated Jupyter 3D viz |
| pythreejs | `pip install pythreejs` | Three.js in Jupyter |
| Trimesh -> GLTF | (export pipeline) | Lightweight models for phone AR |

---

## ADVANCED / FUTURE (Park for Later)

| Library | Purpose | Revisit When |
|---|---|---|
| PyChrono | Multi-physics (flexible bodies, cables, gears) | Complex cable/chain systems |
| python-control | Control theory, stability margins | Reactive/balanced sculptures |
| FilterPy | Kalman filter for sensor fusion | Sensor-equipped installations |
| TouchDesigner | Real-time interactive control | Public interactive installations |
| ROS 2 | Multi-motor coordination (50+ motors) | Large kinetic walls |
| Blender bpy | Generative design exploration | Ideation phase |
| Stable Diffusion + ControlNet | Material/finish visualization | Client presentations |
| compas / compas_fab | Form-finding, robotic fabrication | Robot-assisted assembly |
| Pinocchio / Drake | Rigid body dynamics | Complex multi-body simulation |
| OpenModal / pyOMA2 | Experimental modal analysis | Vibration testing physical prototypes |

---

## CUSTOM SCRIPTS TO BUILD

| Script | Purpose | Priority |
|---|---|---|
| iso286_lookup.py | Shaft/hole fit tolerances per diameter | HIGH — needed for every bearing/shaft |
| galvanic_matrix.py | Corrosion risk for material pairs | HIGH — needed when materials assigned |
| kfactor_calc.py | Sheet metal bend allowance | MEDIUM — needed at production phase |
| weld_sizer.py | Weld sizing per load | MEDIUM — needed for steel production |
| finish_spec.py | Coating recommendation | MEDIUM — needed at production phase |
| bom_generator.py | Extract parts from config -> spreadsheet | HIGH — needed at any phase |
| dfm_advisor.py | Part geometry -> manufacturing method | MEDIUM — needed at production |
| tolerance_stackup.py | Wrapper around dimstack for our config format | HIGH — needed during design |
