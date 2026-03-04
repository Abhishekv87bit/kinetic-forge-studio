# Shape Gate Specification — Pre-Rule-99 Geometric Quality Audit

## Purpose
Shape Gate is a **mandatory design quality gate** that runs BEFORE Rule 99 (functional audit).
Rule 99 asks "will it work?" — Shape Gate asks "does the geometry express its engineering intent?"

Shape changes can invalidate Rule 99 findings (cross-sections change, joints reshape, load paths shift).
Running Rule 99 on unfinished geometry = wasted audit cycles.

## Pipeline Position

```
Step 0: Shape Gate  ← THIS SPEC
Step 1: Rule 99 Full Scan (functional audit on final geometry)
Step 2: Requirements + Implementation
Step 3: Compile + Validate + Render + Consistency Audit
```

## Trigger
- **"Shape Gate"** = full scan, all checks fire
- **"Shape Gate [topic]"** = targeted (joints, transitions, rings, carriers, braces, posts)
- **Auto-trigger:** Before any Rule 99 invocation (Claude checks if Shape Gate was run this version)

## Scope
Shape Gate audits the **frame monolith** and any structural assembly file. It does NOT audit:
- Cam mechanism internals (helix_cam)
- Matrix stack internals (matrix_stack)
- Non-structural visuals (blocks, drive chain)

---

## Audit Categories

### SG-1: Structural Joint Blend Zones
**Question:** Does every joint where two members meet have a deliberate blend zone?

**Checklist:**
| Joint | Members | Min Blend Length | Method |
|-------|---------|-----------------|--------|
| Stub root → ring | Stub beam + hex ring wall | 4mm (STUB_INWARD) | Chamfered beam overlap |
| Stub → junction swell | Stub endpoint + node sphere | 10mm | Hull (sphere + stub face) |
| Junction swell → arm departure | Node sphere + arm profile | 15mm | Hull (sphere + cylinder) |
| Junction vertical spine | Upper swell + lower swell | Full span (45mm) | Hull (sphere + sphere) |
| Arm root → arm body | Junction zone + tapered beam | Continuous via _beam_tapered | 12-segment graduating hull |
| Arm tip → carrier boss | Tapered arm + boss ring | 15mm (_NODE_BLEND_LEN) | Two-side funnel hull |
| Dampener tie → arm | Vertical cylinder + arm pair | Direct hull | Cylinder-to-cylinder hull |
| Linkage → arm | Brace endpoint + arm surface | Direct contact | _beam_curved endpoint |
| Idler bracket → junction | Bracket cube + junction area | Direct hull | Cube-to-cube hull |
| Frame post → ring | Post cylinder + ring wall | None (embedded) | Cylinder inside ring wall |

**Pass criteria:** Every joint has a blend zone >= 2× the smaller member's cross-section dimension.

**Fail examples:**
- Post cylinder (2.5mm dia) meets ring wall with zero blend → needs 5mm boss
- Idler bracket (4mm cube) meets junction with zero taper → needs fillet
- Linkage brace meets arm mid-span with no transition zone → needs funnel

---

### SG-2: Cross-Section Transitions
**Question:** Are all cross-section changes gradual (no abrupt steps > 30% area change)?

**Checklist:**
| Transition | From | To | Ratio | Pass? |
|-----------|------|-----|-------|-------|
| Stub → swell | 10×7=70mm² | π(7)²/4=154mm² | 2.2× | FAIL (>1.3×) |
| Swell → arm | 154mm² | 10×7=70mm² | 0.45× | FAIL (>30% drop) |
| Arm root → arm tip | 70mm² | 6×4.2=25mm² | 0.36× | PASS (gradual over 12 segments) |
| Arm tip → carrier boss | 25mm² | π(8)²/4=201mm² | 8× | FAIL (abrupt hull step) |
| Dampener end → center | 5×7=35mm² | 5×5=25mm² | 0.71× | PASS (gradual over 8 segments) |

**Pass criteria:** Step changes ≤ 30% area ratio at any single joint. Gradual tapers (multi-segment) exempt.

**Remediation for fails:**
- SG-2a: Add intermediate transition cylinder/ellipse at stub→swell boundary
- SG-2b: Extend swell→arm departure zone from 15mm to 25mm
- SG-2c: Add intermediate ring at arm-tip-to-carrier transition (graduated hull)

---

### SG-3: Fillet & Chamfer Hierarchy
**Question:** Do chamfer/fillet radii follow structural hierarchy (primary > secondary > tertiary)?

**Hierarchy levels:**
| Level | Members | Min Chamfer | Purpose |
|-------|---------|-------------|---------|
| Primary (load-bearing) | Stubs, junction spines | 2.0mm | Load transfer roots |
| Secondary (structural) | Arms, carrier nodes | 1.0–1.5mm | Bending resistance |
| Tertiary (bracing) | Linkages, dampener bars | 0.5–1.0mm | Lateral stability |
| Cosmetic | Ring bevels, rim lips | 0.5–1.0mm | Visual finish |

**Pass criteria:** No tertiary member has a larger chamfer than its parent primary/secondary member.

---

### SG-4: Bearing Interface Geometry
**Question:** Does every bearing bore have proper stress relief and mounting expression?

**Checklist:**
| Interface | Bore Dia | Wall Thickness | Rim Expression | Reaming Note |
|-----------|----------|---------------|----------------|--------------|
| Carrier MR84ZZ | 8.15mm | 2.0mm | 0.5mm rim lip | Yes (horizontal FDM) |
| Cam 6704ZZ | 20.0mm | Keeper lip | Lip + seat zone | N/A (vertical) |

**Pass criteria:**
- Wall thickness ≥ 1.5× bearing width (prevents hoop stress failure)
- Edge break (chamfer or radius) on bore entry face ≥ 0.3mm
- Rim lip or chamfer visually expresses the bearing location (reads as "intentional")

---

### SG-5: Gusset & Reinforcement Presence
**Question:** Are high-stress joints reinforced beyond basic hull blending?

**Critical joints requiring reinforcement:**
| Joint | Load Type | Current | Recommended |
|-------|-----------|---------|-------------|
| Stub root at ring | Cantilever bending | 2mm chamfer | Add triangular gusset (stub → ring face) |
| Arm root at junction | Bending moment | Hull blend (15mm) | Extend to 20–25mm + elliptical profile |
| Post base at ring | Axial + lateral | No reinforcement | Add boss collar (5mm dia around 2.5mm post) |
| Idler bracket at junction | Cantilever + torsion | 4mm cube hull | Add wedge gusset |
| Motor bracket | Vibrational | Floating cube | Add mounting tabs to adjacent arms |

**Pass criteria:** Every joint carrying bending moment has a gusset, blend funnel, or extended transition zone.

---

### SG-6: Surface Continuity (Visual Read)
**Question:** Does the frame read as a single designed object, not a wireframe diagram?

**Visual checks (render-based):**
- [ ] Arms visibly taper from thick root to slim tip
- [ ] Junction nodes swell organically (no flat-face cylinders)
- [ ] Carrier bosses read as intentional bearing mounts (not random lumps)
- [ ] Linkages have visible curvature (not ruler-straight)
- [ ] Ring bevels catch light differently from flat faces
- [ ] Dampener bars narrow at center (catenary expression)
- [ ] No "wireframe artifact" — nowhere do two beams cross with zero blending
- [ ] Color hierarchy matches structural hierarchy

**Pass criteria:** All visual checks pass on rendered isometric view.

---

### SG-7: FDM Print Orientation Awareness
**Question:** Are structural joints oriented for FDM layer adhesion?

**Checks:**
| Joint | Print Direction | Layer Adhesion | Risk |
|-------|----------------|---------------|------|
| Vertical spine | Z-axis (good) | Layer lines ⊥ to bending | Low |
| Horizontal arms | XY plane (good) | Layer lines ∥ to arm axis | Low |
| Carrier bore | Horizontal (bad) | Layer lines ⊥ to hoop stress | HIGH — ream post-print |
| Dampener bar | Horizontal bridge | Layer lines sag | MEDIUM — use supports |
| Ring bevels | Z-axis (good) | Smooth outer layers | Low |

**Pass criteria:** No load-bearing joint relies on interlayer adhesion as primary strength path,
or if it does, the design note explicitly acknowledges it with a mitigation (reaming, supports, etc.).

---

## Output Format

```
=== SHAPE GATE AUDIT — [filename] v[version] ===

SG-1: Structural Joint Blend Zones
  [PASS/FAIL] [joint name]: [description]
  ...

SG-2: Cross-Section Transitions
  [PASS/CAUTION/FAIL] [transition]: [ratio] [note]
  ...

SG-3: Fillet & Chamfer Hierarchy
  [PASS/FAIL] [member]: chamfer=[value]mm (expected ≥ [min])

SG-4: Bearing Interface Geometry
  [PASS/FAIL] [bore]: wall=[value]mm, rim=[value]mm

SG-5: Gusset & Reinforcement
  [PASS/ADVISORY] [joint]: [current state] → [recommendation]

SG-6: Surface Continuity
  [PASS/FAIL] Visual checklist: [N]/[total] items pass

SG-7: FDM Print Orientation
  [PASS/CAUTION] [joint]: [orientation] [risk level]

VERDICT: [PASS / CONDITIONAL PASS / FAIL]
  [N] pass, [N] caution, [N] fail
  Blocking items: [list if any]
```

---

## Relationship to Rule 99

| Shape Gate | Rule 99 |
|-----------|---------|
| Runs FIRST | Runs SECOND |
| Geometric quality | Functional correctness |
| "Does it look engineered?" | "Will it work?" |
| Blend zones, transitions, fillets | Clearances, tolerances, bearing life |
| Visual render check | Quantified stress/motion analysis |
| Blocks Rule 99 if FAIL | Blocks delivery if FAIL |

Shape Gate FAIL = fix geometry first, then Rule 99.
Shape Gate PASS = proceed to Rule 99 with confidence that geometry is final.

---

## Implementation Notes
- Shape Gate is a **manual audit** (Claude reads geometry, checks against spec)
- No separate Python script needed (unlike validate_geometry.py)
- Results written to echo strings or conversation output
- Future: could be automated with OpenSCAD assertions on cross-section areas
