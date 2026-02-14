import math

HELIX_ANGLES = [180, 300, 60]
HELIX_R = 271.9
HELIX_LENGTH = 182.0
JOURNAL_LENGTH = 10.0
JOURNAL_EXT = 150.0
ARM_W = 20.0
ARM_H = 14.0
GT2_OD = 14.2
JUNCTION_R = 170.0
STAR_TIP_R = 354.0
ARM_DEFS = [(0, -37), (0, 37), (120, 83), (120, 157), (240, 203), (240, 277)]
HELIX_ARM_PAIRS = [[3, 4], [5, 0], [1, 2]]
HN = ["H1", "H2", "H3"]

def d2r(d): return math.radians(d)
def v2(a, r): return (r*math.cos(d2r(a)), r*math.sin(d2r(a)))
def mg(p): return math.sqrt(p[0]**2+p[1]**2)
def su(a,b): return (a[0]-b[0],a[1]-b[1])
def lp(a,b,t): return (a[0]+t*(b[0]-a[0]), a[1]+t*(b[1]-a[1]))


total_reach = HELIX_LENGTH/2.0 + JOURNAL_LENGTH + JOURNAL_EXT
sep = chr(61) * 80

print(sep)
print('PART 1: HELIX SHAFT and BEARING GEOMETRY')
print(sep)
print()
print('Total journal reach = %.1f/2 + %.1f + %.1f = %.1f mm' % (HELIX_LENGTH, JOURNAL_LENGTH, JOURNAL_EXT, total_reach))
print()

helix_data = []
for i, angle in enumerate(HELIX_ANGLES):
    name = HN[i]
    a = d2r(angle)
    cx, cy = HELIX_R*math.cos(a), HELIX_R*math.sin(a)
    sx, sy = -math.sin(a), math.cos(a)
    nx, ny = cx-sx*total_reach, cy-sy*total_reach
    fx, fy = cx+sx*total_reach, cy+sy*total_reach
    nr, fr = mg((nx,ny)), mg((fx,fy))
    helix_data.append(dict(name=name, angle=angle, center=(cx,cy), shaft_dir=(sx,sy),
                           near=(nx,ny), far=(fx,fy), near_r=nr, far_r=fr))
    print('--- %s (angle=%d deg) ---' % (name, angle))
    print('  Center:     (%8.2f, %8.2f)   R = %.2f' % (cx, cy, mg((cx,cy))))
    print('  Shaft dir:  (%8.4f, %8.4f)' % (sx, sy))
    print('  Near brg:   (%8.2f, %8.2f)   R = %.2f' % (nx, ny, nr))
    print('  Far  brg:   (%8.2f, %8.2f)   R = %.2f' % (fx, fy, fr))
    print()

print(sep)
print('PART 2: ARM GEOMETRY')
print(sep)
print()

arm_data = []
for idx in range(len(ARM_DEFS)):
    sa, ta = ARM_DEFS[idx]
    start = v2(sa, JUNCTION_R)
    end = v2(ta, STAR_TIP_R)
    positions = {}
    for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
        positions[f] = lp(start, end, f)
    arm_data.append(dict(index=idx, stub_ang=sa, tip_ang=ta, start=start, end=end, positions=positions))
    print('--- A%d (stub=%d deg, tip=%d deg) ---' % (idx, sa, ta))
    print('  Start (junction): (%8.2f, %8.2f)  R=%.2f' % (start[0], start[1], mg(start)))
    print('  End   (star tip): (%8.2f, %8.2f)  R=%.2f' % (end[0], end[1], mg(end)))
    for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
        p = positions[f]
        print('  @%.2f:            (%8.2f, %8.2f)  R=%.2f' % (f, p[0], p[1], mg(p)))
    print()

print(sep)
print('PART 3: SHAFT-AXIS PROJECTION (ARM POINTS vs HELIX CENTER)')
print(sep)
print()
print('Positive = toward far bearing, Negative = toward near bearing.')
print()

for i, hd in enumerate(helix_data):
    name = hd['name']
    hc = hd['center']
    sd = hd['shaft_dir']
    arm_pair = HELIX_ARM_PAIRS[i]
    print('--- %s (angle=%d deg) ---' % (name, hd['angle']))
    print('  Helix center: (%8.2f, %8.2f)' % (hc[0], hc[1]))
    print('  Shaft dir:    (%8.4f, %8.4f)' % (sd[0], sd[1]))
    print('  Near brg at shaft dist = -%.1f mm' % total_reach)
    print('  Far  brg at shaft dist = +%.1f mm' % total_reach)
    print()
    print('  %5s %5s %9s %9s %10s %10s %12s' % ('Arm', 'Frac', 'X', 'Y', 'ShaftDist', 'PerpDist', 'FromOriginR'))
    print('  ' + chr(45)*65)
    for ai in arm_pair:
        ad = arm_data[ai]
        for f in [0.5, 0.75, 1.0]:
            p = ad['positions'][f]
            dx, dy = p[0]-hc[0], p[1]-hc[1]
            shaft_dist = dx*sd[0]+dy*sd[1]
            perp_dist = abs(dx*(-sd[1])+dy*sd[0])
            r = mg(p)
            print('  A%3d %5.2f %9.2f %9.2f %+10.2f %10.2f %12.2f' % (ai, f, p[0], p[1], shaft_dist, perp_dist, r))
    print()

print(sep)
print('PART 4: BEARING vs ARM GAP ANALYSIS')
print(sep)
print()

for i, hd in enumerate(helix_data):
    name = hd['name']
    arm_pair = HELIX_ARM_PAIRS[i]
    print('--- %s ---' % name)
    for bl, bp, bsd in [('Near', hd['near'], -total_reach), ('Far', hd['far'], +total_reach)]:
        print('  %s bearing: (%8.2f, %8.2f)  shaft_dist=%+.1f' % (bl, bp[0], bp[1], bsd))
        best_gap = float('inf')
        best_info = ''
        for ai in arm_pair:
            ad = arm_data[ai]
            for fi in range(0, 101, 5):
                f = fi/100.0
                p = lp(ad['start'], ad['end'], f)
                gap = mg(su(p, bp))
                if gap < best_gap:
                    best_gap = gap
                    best_info = 'A%d@%.2f (%.2f, %.2f)' % (ai, f, p[0], p[1])
        print('    Closest arm point: %s' % best_info)
        print('    Gap (center-to-center): %.2f mm' % best_gap)
        print('    Approx clearance (- ARM_W/2=%.1f): %.2f mm' % (ARM_W/2, best_gap-ARM_W/2))
        print()

print(sep)
print('PART 5: SHAFT-AXIS OVERLAP CHECK')
print(sep)
print()
print('Points where arm projects IN RANGE of shaft bearings (perp < 50mm flagged).')
print()

for i, hd in enumerate(helix_data):
    name = hd['name']
    hc = hd['center']
    sd = hd['shaft_dir']
    arm_pair = HELIX_ARM_PAIRS[i]
    print('--- %s ---' % name)
    for ai in arm_pair:
        ad = arm_data[ai]
        print('  Arm A%d (stub=%d, tip=%d):' % (ai, ad['stub_ang'], ad['tip_ang']))
        found = False
        for fi in range(0, 101, 10):
            f = fi/100.0
            p = lp(ad['start'], ad['end'], f)
            dx, dy = p[0]-hc[0], p[1]-hc[1]
            sp = dx*sd[0]+dy*sd[1]
            pp = abs(dx*(-sd[1])+dy*sd[0])
            if abs(sp) <= total_reach:
                found = True
                flag = ' *** CLOSE' if pp < 50 else ''
                print('    @%.2f: shaft=%+8.2f perp=%7.2f  IN RANGE%s' % (f, sp, pp, flag))
        if not found:
            print('    (no points within shaft range)')
        print()
    print()

print(sep)
print('PART 6: SUMMARY TABLE')
print(sep)
print()
hdr = '%6s | %5s | %9s %9s %8s | %14s | %8s | %10s' % ('Helix','Brg','Brg X','Brg Y','Brg R','Nearest Arm','Gap mm','Clearance')
print(hdr)
print(chr(45)*len(hdr))
for i, hd in enumerate(helix_data):
    name = hd['name']
    arm_pair = HELIX_ARM_PAIRS[i]
    for bl, bp in [('Near', hd['near']), ('Far', hd['far'])]:
        best_gap = float('inf')
        best_arm = ''
        for ai in arm_pair:
            ad = arm_data[ai]
            for fi in range(0, 101, 1):
                f = fi/100.0
                p = lp(ad['start'], ad['end'], f)
                gap = mg(su(p, bp))
                if gap < best_gap:
                    best_gap = gap
                    best_arm = 'A%d@%.2f' % (ai, f)
        br = mg(bp)
        clr = best_gap - ARM_W/2
        print('%6s | %5s | %9.2f %9.2f %8.2f | %14s | %8.2f | %+10.2f' % (name, bl, bp[0], bp[1], br, best_arm, best_gap, clr))
print()
print('Clearance = Gap - ARM_W/2 (approximate)')
print()

print(sep)
print('PART 7: GT2 PULLEY POSITIONS ON SHAFT ENDS')
print(sep)
print()
print('GT2 pulley OD = %.1f mm' % GT2_OD)
print()
for i, hd in enumerate(helix_data):
    print('%s: Near (%.2f, %.2f), Far (%.2f, %.2f)' % (hd['name'], hd['near'][0], hd['near'][1], hd['far'][0], hd['far'][1]))
print()
print('Inter-helix pulley distances:')
for i in range(len(helix_data)):
    for j in range(i+1, len(helix_data)):
        h1, h2 = helix_data[i], helix_data[j]
        for l1, p1 in [('Near', h1['near']), ('Far', h1['far'])]:
            for l2, p2 in [('Near', h2['near']), ('Far', h2['far'])]:
                d = mg(su(p1, p2))
                print('  %s.%s -> %s.%s: %.2f mm' % (h1['name'], l1, h2['name'], l2, d))
print()
print('Done.')
