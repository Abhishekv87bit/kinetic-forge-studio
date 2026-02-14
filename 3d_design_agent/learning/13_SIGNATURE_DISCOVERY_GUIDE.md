# Signature Mechanism Discovery Guide
## Finding Your "Holy Numbers" - A Computational Approach to Kinetic Art

---

## Why This Matters

Every master kinetic sculptor has their signature:
- **Theo Jansen** → Evolved linkage ratios (13 holy numbers)
- **Reuben Margolin** → Helix-driven string/pulley wave systems
- **David C. Roy** → Weight-driven escapements
- **Anthony Howe** → Compound rotation (rotating while orbiting)
- **Bob Potts** → Specific cam-based timing systems

You have something they didn't: **modern computational tools + 18 months to explore**.

---

## The Jansen Precedent

In 1990, Theo Jansen spent months on an Atari ST running genetic algorithms. His search space: 13 link lengths. His fitness function: smooth walking motion. The result: ratios that define all Strandbeest legs for 30+ years.

**What made this valuable:**
1. Finite, simulatable search space
2. Fitness function matched aesthetic goal
3. New primitive others hadn't explored deeply
4. Committed to ONE domain for decades

**Your opportunity:** Same approach, but with 2026 tools and unexplored territories.

---

## Unexplored Territories (Beyond Linkages)

| Domain | What's Unexplored | Why Interesting | Simulatable? |
|--------|-------------------|-----------------|--------------|
| **Magnetic Coupling** | Contactless motion, repulsion orbits | No friction, spooky action | Yes (Magpylib) |
| **Elastic Bistability** | LaMSA springs, snap-through | Energy storage + sudden release | Yes (spring ODEs) |
| **Tensegrity Oscillation** | Pretension-driven, cable networks | Floating, impossible structures | Yes (particle systems) |
| **Phase-Coupled Oscillators** | Kuramoto sync/desync | Firefly emergence, complexity | Yes (NetworkX + ODEs) |
| **Helix-Driven Waves** | Margolin-inspired string paths | Meditative, mathematical | Yes (geometry) |
| **Compound Pendulums** | Chaotic vs periodic regimes | Hypnotic, minimal input | Yes (Lagrangian) |
| **Gravity Manipulation** | Meta-stable states, balance | David C. Roy territory | Yes (energy methods) |

---

## Your Unique Position

**Computer engineer** + **Python/Claude access** + **Simulation capability** + **18-month runway**

Tools at your disposal:
- **DEAP/Pymoo** → Genetic algorithms
- **NumPy/SciPy** → Physics simulation
- **Matplotlib/Plotly** → Visualization
- **Magpylib** → Magnetic field simulation
- **NetworkX** → Graph-based oscillator coupling
- **OpenSCAD** → Physical realization
- **Claude** → Code generation and iteration

---

## 4-Phase Discovery Framework

### Phase 1: Sampling (Months 1-4)
**Goal:** Try 5 domains, find what resonates

| Month | Domain | Experiment | Time | Tools |
|-------|--------|------------|------|-------|
| 1 | **Linkages** (baseline) | 3 four-bar variations | 8 hrs | Pyslvs, cardboard |
| 2 | **Cams** | 3 cam profiles, compare feel | 8 hrs | OpenSCAD, cardboard |
| 3 | **Pendulums** | Compound, chaotic vs periodic | 8 hrs | SciPy ODE, weight |
| 4 | **Elastic** | Rubber band engine, snaps | 8 hrs | Cardboard, rubber |
| 4+ | **Helix-Wave** | String through pulleys | 8 hrs | String, weights |

**Evaluation:** Which domain made you want to keep exploring?

### Phase 2: Deep Dive (Months 5-8)
**Goal:** Understand your chosen domain's parameter space

**If Magnetic Coupling:**
```python
# Parameters: magnet strength, distances, angles, masses
# Fitness: orbit smoothness, energy efficiency
# Tool: Magpylib + DEAP
```

**If Compound Pendulums:**
```python
# Parameters: arm lengths L1/L2, masses M1/M2, initial angles
# Fitness: time in chaotic regime, visual complexity
# Tool: SciPy ODE + DEAP
```

**If Phase-Coupled Oscillators:**
```python
# Parameters: natural frequencies ω_i, coupling K
# Fitness: sync time, pattern complexity, emergence
# Tool: NetworkX + NumPy
```

**If Helix-Driven Waves:**
```python
# Parameters: helix pitch, radius, string lengths, element spacing
# Fitness: wave smoothness, phase relationships
# Tool: Geometry + OpenSCAD
```

### Phase 3: Evolution (Months 9-12)
**Goal:** Run genetic algorithms to find YOUR holy numbers

**Framework:**
```
1. DEFINE SEARCH SPACE
   - What parameters can vary?
   - What are reasonable bounds?
   - How many dimensions? (Jansen had 13)

2. DEFINE FITNESS FUNCTION
   - What makes motion "feel alive"?
   - What makes it "meditative"?
   - Measurable proxies: smoothness, periodicity, energy

3. RUN EVOLUTION
   - Population: 50-100 individuals
   - Generations: 500-1000
   - Selection: tournament or rank-based
   - Log EVERYTHING for later analysis

4. ANALYZE RESULTS
   - Visualize the evolved designs
   - Find patterns in the winners
   - Test physical prototypes
```

### Phase 4: Signature (Months 13-18)
**Goal:** Refine discovered mechanism into YOUR signature

- Build physical prototypes of best evolved designs
- Document the discovery process (this IS your story)
- Create a "recipe book" for your mechanism type
- Develop variations and combinations
- Name your system (like "Strandbeest" or "Triple Helix")

---

## Fitness Functions for Aesthetic Goals

| Your Goal | Measurable Proxy | Computation |
|-----------|------------------|-------------|
| "Feels alive" | Velocity variation within bounds | `σ(v)` where `v_min < v < v_max` |
| "Meditative calm" | Low acceleration, smooth | `∫|a(t)|dt` minimized |
| "Organic" | Non-repetitive within period | FFT spectrum width |
| "Surprising" | Periodic with subharmonics | Period detection + modulation |
| "Balanced" | Symmetric force distribution | Center of mass variance |
| "Hypnotic" | Near-periodic but not quite | Autocorrelation analysis |

### Compound Fitness Example
```python
def aesthetic_fitness(trajectory):
    """Multi-objective fitness for meditative motion."""

    # Extract position, velocity, acceleration
    pos = trajectory['position']
    vel = np.gradient(pos, trajectory['time'])
    acc = np.gradient(vel, trajectory['time'])

    # Objective 1: Smoothness (low jerk)
    jerk = np.gradient(acc, trajectory['time'])
    smoothness = 1.0 / (1.0 + np.std(jerk))

    # Objective 2: Aliveness (velocity variation)
    aliveness = np.std(vel) / (np.mean(np.abs(vel)) + 1e-6)

    # Objective 3: Periodicity (but not boring)
    fft = np.fft.fft(pos)
    spectral_spread = np.std(np.abs(fft[:len(fft)//2]))
    periodicity = 1.0 / (1.0 + spectral_spread)

    # Weighted combination (tune these!)
    return 0.4 * smoothness + 0.3 * aliveness + 0.3 * periodicity
```

---

## Domain-Specific Simulation Guides

### 1. Magnetic Coupling
```python
import magpylib as magpy
import numpy as np

# Create dipole magnets
magnet1 = magpy.magnet.Cylinder(
    polarization=(0, 0, 1),  # Tesla
    dimension=(10, 5)         # mm: diameter, height
)
magnet2 = magpy.magnet.Cylinder(
    polarization=(0, 0, 1),
    dimension=(10, 5)
)

# Position second magnet
magnet2.position = (30, 0, 0)  # 30mm away

# Calculate field at points
points = np.array([[20, 0, 0], [25, 0, 0], [30, 0, 0]])
B = magpy.getB(magnet1, points)

# For dynamics: F = ∇(m·B)
# Use scipy.integrate.odeint to evolve
```

### 2. Compound Pendulum (Double)
```python
import numpy as np
from scipy.integrate import odeint

def double_pendulum(state, t, L1, L2, M1, M2, g=9.81):
    """Equations of motion for double pendulum."""
    θ1, ω1, θ2, ω2 = state

    Δθ = θ2 - θ1
    den1 = (M1 + M2) * L1 - M2 * L1 * np.cos(Δθ)**2
    den2 = (L2 / L1) * den1

    dω1 = (M2 * L1 * ω1**2 * np.sin(Δθ) * np.cos(Δθ)
           + M2 * g * np.sin(θ2) * np.cos(Δθ)
           + M2 * L2 * ω2**2 * np.sin(Δθ)
           - (M1 + M2) * g * np.sin(θ1)) / den1

    dω2 = (-M2 * L2 * ω2**2 * np.sin(Δθ) * np.cos(Δθ)
           + (M1 + M2) * g * np.sin(θ1) * np.cos(Δθ)
           - (M1 + M2) * L1 * ω1**2 * np.sin(Δθ)
           - (M1 + M2) * g * np.sin(θ2)) / den2

    return [ω1, dω1, ω2, dω2]

# Parameters to evolve
L1, L2 = 1.0, 1.0  # arm lengths
M1, M2 = 1.0, 1.0  # masses

# Initial conditions
θ1_0, θ2_0 = np.pi/2, np.pi/2
state0 = [θ1_0, 0, θ2_0, 0]

# Simulate
t = np.linspace(0, 20, 2000)
solution = odeint(double_pendulum, state0, t, args=(L1, L2, M1, M2))
```

### 3. Phase-Coupled Oscillators (Kuramoto)
```python
import numpy as np
from scipy.integrate import odeint
import networkx as nx

def kuramoto(phases, t, omega, K, adj_matrix):
    """Kuramoto model: dθ_i/dt = ω_i + K * Σ A_ij * sin(θ_j - θ_i)"""
    N = len(phases)
    dphases = np.zeros(N)

    for i in range(N):
        coupling = 0
        for j in range(N):
            if adj_matrix[i, j]:
                coupling += np.sin(phases[j] - phases[i])
        dphases[i] = omega[i] + K * coupling / N

    return dphases

# Create coupling network
N = 10  # oscillators
G = nx.watts_strogatz_graph(N, 4, 0.3)  # small-world network
adj = nx.to_numpy_array(G)

# Natural frequencies (slightly different)
omega = np.random.normal(1.0, 0.1, N)

# Coupling strength (evolve this!)
K = 0.5

# Random initial phases
phases0 = np.random.uniform(0, 2*np.pi, N)

# Simulate
t = np.linspace(0, 50, 5000)
solution = odeint(kuramoto, phases0, t, args=(omega, K, adj))
```

### 4. Elastic Bistability (Snap-Through)
```python
import numpy as np
from scipy.integrate import odeint

def bistable_spring(state, t, k, d, x_stable, damping):
    """Bistable potential: U(x) = k*(x^2 - x_stable^2)^2"""
    x, v = state

    # Force from bistable potential
    F = -4 * k * x * (x**2 - x_stable**2)

    # Damping
    F -= damping * v

    # Could add periodic driving here
    # F += A * np.sin(omega * t)

    return [v, F]

# Parameters
k = 1.0           # stiffness
x_stable = 1.0    # stable positions at ±x_stable
damping = 0.1     # friction

# Start near unstable equilibrium
state0 = [0.1, 0]

t = np.linspace(0, 20, 2000)
solution = odeint(bistable_spring, state0, t, args=(k, 0, x_stable, damping))
```

### 5. Helix-Driven Wave (Margolin-Inspired)
```python
import numpy as np

def helix_wave_position(t, element_idx, params):
    """Calculate element position from rotating helix."""

    helix_radius = params['helix_radius']
    helix_pitch = params['helix_pitch']
    omega = params['rotation_speed']
    num_elements = params['num_elements']

    # Phase offset for this element
    phase = 2 * np.pi * element_idx / num_elements

    # Helix rotation
    theta = omega * t + phase

    # Vertical position from helix
    z = helix_radius * np.sin(theta)

    # Could add string path complexity here
    return z

# Parameters to evolve
params = {
    'helix_radius': 50,      # mm
    'helix_pitch': 100,      # mm per rotation
    'rotation_speed': 1.0,   # rad/s
    'num_elements': 20
}

# Simulate
t = np.linspace(0, 10, 1000)
positions = np.array([
    [helix_wave_position(ti, i, params) for i in range(params['num_elements'])]
    for ti in t
])
```

---

## Genetic Algorithm Framework (DEAP)

```python
from deap import base, creator, tools, algorithms
import numpy as np

# 1. DEFINE FITNESS (maximize aesthetic score)
creator.create("FitnessMax", base.Fitness, weights=(1.0,))
creator.create("Individual", list, fitness=creator.FitnessMax)

# 2. DEFINE SEARCH SPACE
# Example: 5 parameters for compound pendulum
PARAM_BOUNDS = [
    (0.5, 2.0),   # L1: arm 1 length
    (0.5, 2.0),   # L2: arm 2 length
    (0.5, 2.0),   # M1: mass 1
    (0.5, 2.0),   # M2: mass 2
    (0.1, np.pi), # θ0: initial angle
]

def create_individual():
    return [np.random.uniform(lo, hi) for lo, hi in PARAM_BOUNDS]

# 3. EVALUATION FUNCTION
def evaluate(individual):
    L1, L2, M1, M2, theta0 = individual

    # Simulate the system
    trajectory = simulate_pendulum(L1, L2, M1, M2, theta0)

    # Calculate fitness
    fitness = aesthetic_fitness(trajectory)

    return (fitness,)  # Must be tuple

# 4. SETUP TOOLBOX
toolbox = base.Toolbox()
toolbox.register("individual", tools.initIterate, creator.Individual, create_individual)
toolbox.register("population", tools.initRepeat, list, toolbox.individual)
toolbox.register("evaluate", evaluate)
toolbox.register("mate", tools.cxBlend, alpha=0.5)
toolbox.register("mutate", tools.mutGaussian, mu=0, sigma=0.1, indpb=0.2)
toolbox.register("select", tools.selTournament, tournsize=3)

# 5. RUN EVOLUTION
def main():
    pop = toolbox.population(n=100)

    # Statistics
    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("avg", np.mean)
    stats.register("max", np.max)

    # Hall of fame (best individuals)
    hof = tools.HallOfFame(10)

    # Run
    pop, log = algorithms.eaSimple(
        pop, toolbox,
        cxpb=0.7,    # crossover probability
        mutpb=0.2,   # mutation probability
        ngen=500,    # generations
        stats=stats,
        halloffame=hof,
        verbose=True
    )

    return hof, log

if __name__ == "__main__":
    best, history = main()
    print("Best parameters:", best[0])
    print("Fitness:", best[0].fitness.values[0])
```

---

## Integration with 18-Month Curriculum

```
MONTH 1-4:   Learn fundamentals + SAMPLE domains (8 hrs each)
             ↓
             [DECISION: Which domain resonates?]
             ↓
MONTH 5-8:   Master fundamentals + DEEP DIVE chosen domain
             ↓
             [Build simulation framework]
             ↓
MONTH 9-12:  Integration projects + RUN EVOLUTION
             ↓
             [Find your "holy numbers"]
             ↓
MONTH 13-18: Original works using YOUR SIGNATURE MECHANISM
```

### Parallel Activities
| Month Range | Main Curriculum | Signature Discovery |
|-------------|-----------------|---------------------|
| 1-4 | Four-bar mastery, Wave mechanism | Sample 4-5 domains |
| 5-8 | Cams, gears, Birds+Rice Tube | Deep dive simulation |
| 9-12 | Moon, Cypress, Full Starry Night | Run evolution, prototype |
| 13-18 | Original sculptures | Refine and name your system |

---

## What Success Looks Like

### Month 4: Domain Chosen
- Tried all 5 sampling domains
- One clearly excited you more
- Written reflection on why

### Month 8: Simulation Working
- Can simulate your domain in Python
- Understand the parameter space
- Have initial fitness function ideas

### Month 12: Evolution Complete
- Ran 500+ generations
- Found interesting parameter regions
- Built 2-3 physical prototypes
- Documented your "holy numbers"

### Month 18: Signature Established
- Named your mechanism system
- Have 3+ sculptures using it
- Can explain the discovery story
- Portfolio-ready documentation

---

## Files in This System

| File | Purpose |
|------|---------|
| `13_SIGNATURE_DISCOVERY_GUIDE.md` | This document |
| `14_EXPERIMENT_LOG.md` | Track what you try |
| `tools/domain_sampler.py` | Quick domain experiments |
| `tools/fitness_functions.py` | Aesthetic metrics library |
| `tools/evolution_framework.py` | DEAP wrapper for any domain |

---

## Next Steps

1. **Install dependencies:** `pip install deap magpylib networkx`
2. **Run domain_sampler.py --demo** to see all domains
3. **Start sampling** in Month 1 (parallel with linkage learning)
4. **Keep experiment log** - document gut reactions
5. **Choose domain at Month 4** - trust your resonance

Remember: Jansen didn't know Strandbeest would become his life's work when he started. He just kept exploring what fascinated him.

---

*"The goal is not to find the objectively best mechanism. The goal is to find YOUR mechanism - the one that speaks to you, that you want to keep exploring, that becomes your artistic voice."*
