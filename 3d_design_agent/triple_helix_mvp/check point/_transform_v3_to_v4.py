
import os, re

with open('3d_design_agent/triple_helix_mvp/Archive/helix_cam_v3.scad', 'r', encoding='utf-8') as f:
    v3 = f.read()

lines = v3.split('\n')

# Identify line ranges to KEEP vs REMOVE
# Strategy: build output by explicitly selecting what to keep

out = []

# Section 1: Header comment block (lines 0-28 approx) - KEEP but update V3->V4
i = 0
while i < len(lines) and (lines[i].startswith('//') or lines[i].strip() == ''):
    ln = lines[i].replace('HELIX CAM V3', 'HELIX CAM V4')
    # Add V4 changes note after "progressive twist" line
    out.append(ln)
    if 'One cam per channel' in ln:
        out.append('//')
        out.append('// V4 CHANGES:')
        out.append('//   - All parameters from config_v4.scad (single source of truth)')
        out.append('//   - Removed helix_positioned_v3() \u2014 hex_frame does its own positioning')
        out.append('//   - BOLT_CLEARANCE \u2192 BOLT_CLEARANCE_D (name collision fix)')
    i += 1

# Insert include directive
out.append('')
out.append('include <config_v4.scad>')
out.append('')
out.append(' = 40;')

# Skip everything until DISPLAY TOGGLES
while i < len(lines):
    if 'DISPLAY TOGGLES' in lines[i]:
        break
    i += 1

# Keep DISPLAY TOGGLES section
out.append('')
while i < len(lines):
    if 'VERIFICATION' in lines[i] and '======' in lines[i-1]:
        # Keep verification section header
        out.append(lines[i-1])  # ====== line
        break
    out.append(lines[i])
    i += 1

# Keep VERIFICATION section but update V3->V4
while i < len(lines):
    ln = lines[i].replace('HELIX CAM V3', 'HELIX CAM V4')
    out.append(ln)
    if 'STANDALONE RENDER' in ln:
        break
    i += 1

# Keep from STANDALONE RENDER through helix_assembly_v3 module
while i < len(lines):
    out.append(lines[i])
    if lines[i].strip().startswith('helix_assembly_v3(anim_t'):
        break
    i += 1
i += 1

# Find and keep helix_assembly_v3 module
while i < len(lines):
    if 'HELIX ASSEMBLY' in lines[i] and '======' in lines[i]:
        break
    i += 1

# Keep from HELIX ASSEMBLY header through end of module
brace_depth = 0
module_started = False
while i < len(lines):
    out.append(lines[i])
    if 'module helix_assembly_v3' in lines[i]:
        module_started = True
    if module_started:
        brace_depth += lines[i].count('{') - lines[i].count('}')
        if brace_depth == 0 and module_started and '{' in ''.join(lines[:i+1]):
            i += 1
            break
    i += 1

# Find ECCENTRIC DISC module section
while i < len(lines):
    if 'ECCENTRIC DISC' in lines[i] and '======' in lines[i]:
        break
    i += 1

# Keep eccentric disc section + module, replacing BOLT_CLEARANCE
brace_depth = 0
module_started = False
while i < len(lines):
    ln = lines[i]
    if 'BOLT_CLEARANCE' in ln and 'module' not in ln and not ln.strip().startswith('//'):
        ln = ln.replace('BOLT_CLEARANCE', 'BOLT_CLEARANCE_D')
    out.append(ln)
    if 'module eccentric_disc' in ln:
        module_started = True
    if module_started:
        brace_depth += ln.count('{') - ln.count('}')
        if brace_depth == 0:
            i += 1
            break
    i += 1

# Find BEARING 6800ZZ module
while i < len(lines):
    if 'BEARING 6800ZZ' in lines[i] and '======' in lines[i]:
        break
    i += 1

# Keep bearing module
brace_depth = 0
module_started = False
while i < len(lines):
    out.append(lines[i])
    if 'module _bearing_6800zz' in lines[i]:
        module_started = True
    if module_started:
        brace_depth += lines[i].count('{') - lines[i].count('}')
        if brace_depth == 0:
            i += 1
            break
    i += 1

# Find BOLT SET module
while i < len(lines):
    if 'BOLT SET' in lines[i] and '======' in lines[i]:
        break
    i += 1

# Keep bolt set module
brace_depth = 0
module_started = False
while i < len(lines):
    out.append(lines[i])
    if 'module _bolt_set' in lines[i]:
        module_started = True
    if module_started:
        brace_depth += lines[i].count('{') - lines[i].count('}')
        if brace_depth == 0:
            i += 1
            break
    i += 1

# Find GRAVITY RIB module
while i < len(lines):
    if 'GRAVITY RIB' in lines[i] and '======' in lines[i]:
        break
    i += 1

# Keep gravity rib module
brace_depth = 0
module_started = False
while i < len(lines):
    out.append(lines[i])
    if 'module gravity_rib_v3' in lines[i]:
        module_started = True
    if module_started:
        brace_depth += lines[i].count('{') - lines[i].count('}')
        if brace_depth == 0:
            i += 1
            break
    i += 1

# Find GT2 PULLEY BOSS module
while i < len(lines):
    if 'GT2 PULLEY BOSS' in lines[i] and '======' in lines[i]:
        break
    i += 1

# Keep GT2 module
brace_depth = 0
module_started = False
while i < len(lines):
    out.append(lines[i])
    if 'module gt2_pulley_boss' in lines[i]:
        module_started = True
    if module_started:
        brace_depth += lines[i].count('{') - lines[i].count('}')
        if brace_depth == 0:
            i += 1
            break
    i += 1

# SKIP helix_positioned_v3 module (everything remaining)

# Clean up multiple blank lines
result = '\n'.join(out) + '\n'
while '\n\n\n\n' in result:
    result = result.replace('\n\n\n\n', '\n\n\n')

with open('3d_design_agent/triple_helix_mvp/helix_cam_v4.scad', 'w', encoding='utf-8') as f:
    f.write(result)

# Verification
print('Written V4:', len(result), 'chars')
print('Has include:', 'include <config_v4.scad>' in result)
print('Has helix_positioned:', 'helix_positioned_v3' in result)
bc = result.count('BOLT_CLEARANCE')
bcd = result.count('BOLT_CLEARANCE_D')
print('BOLT_CLEARANCE refs:', bc, '| BOLT_CLEARANCE_D refs:', bcd, '| non-D refs:', bc - bcd)
print('V3 in echoes:', 'HELIX CAM V3' in result)
print('V4 in echoes:', 'HELIX CAM V4' in result)
print('Has C_DISC =:', 'C_DISC    =' in result)
print('Has color(C_DISC):', 'color(C_DISC)' in result)
print('Has MANUAL_POSITION =:', 'MANUAL_POSITION =' in result)
