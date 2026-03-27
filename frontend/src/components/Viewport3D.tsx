/**
 * SC-04 Viewport3D — Three.js / React Three Fiber 3-D canvas.
 *
 * Loads the active module's geometry as a GLB from the backend and renders
 * it in the scene.  Auto-reloads whenever `geometryVersion` in viewportStore
 * is bumped (i.e. after a successful module execution).
 *
 * URL pattern:  /api/modules/{activeModuleId}/geometry?v={geometryVersion}
 * The `?v=` cache-buster forces Three.js's GLTFLoader to refetch on each
 * geometry rebuild without requiring a page reload.
 *
 * VLAD status overlay: shows a coloured badge (PASS / FAIL / pending) in the
 * top-right corner of the canvas based on the active module's vladSummary.
 */
import React, { Suspense, useEffect, useRef } from 'react';
import { Canvas, useLoader, useThree } from '@react-three/fiber';
import { OrbitControls, Center, Environment, Html } from '@react-three/drei';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader';
import * as THREE from 'three';

import { useViewportStore } from '../stores/viewportStore';
import { useModuleStore } from '../stores/moduleStore';

// ---------------------------------------------------------------------------
// Inner mesh that loads and displays the GLB
// ---------------------------------------------------------------------------

interface GeometryMeshProps {
  url: string;
  onLoad: () => void;
  onError: (err: string) => void;
}

function GeometryMesh({ url, onLoad, onError }: GeometryMeshProps) {
  const gltf = useLoader(GLTFLoader, url, undefined, (err) => {
    onError(err instanceof Error ? err.message : String(err));
  });

  useEffect(() => {
    if (gltf) {
      // Centre model and compute bounding box for camera fit
      onLoad();
    }
  }, [gltf, onLoad]);

  if (!gltf) return null;

  return (
    <Center>
      <primitive object={gltf.scene} />
    </Center>
  );
}

// ---------------------------------------------------------------------------
// VLAD status overlay (rendered inside Canvas via Html from drei)
// ---------------------------------------------------------------------------

type VladVerdict = 'PASS' | 'FAIL' | 'pending' | 'none';

interface VladOverlayProps {
  verdict: VladVerdict;
  failCount?: number;
}

function VladOverlay({ verdict, failCount }: VladOverlayProps) {
  if (verdict === 'none') return null;

  const colours: Record<VladVerdict, string> = {
    PASS: '#22c55e',   // green-500
    FAIL: '#ef4444',   // red-500
    pending: '#f59e0b', // amber-500
    none: 'transparent',
  };

  const label =
    verdict === 'FAIL' && failCount !== undefined
      ? `VLAD FAIL (${failCount})`
      : `VLAD ${verdict}`;

  return (
    <Html position={[0, 0, 0]} style={{ position: 'absolute', top: 12, right: 12 }}>
      <div
        style={{
          background: colours[verdict],
          color: '#fff',
          padding: '3px 10px',
          borderRadius: 4,
          fontSize: 12,
          fontWeight: 700,
          fontFamily: 'monospace',
          boxShadow: '0 1px 4px rgba(0,0,0,0.3)',
          pointerEvents: 'none',
        }}
      >
        {label}
      </div>
    </Html>
  );
}

// ---------------------------------------------------------------------------
// Scene — wraps mesh + controls + VLAD overlay
// ---------------------------------------------------------------------------

interface SceneProps {
  geometryUrl: string;
  vladVerdict: VladVerdict;
  vladFailCount?: number;
}

function Scene({ geometryUrl, vladVerdict, vladFailCount }: SceneProps) {
  const { setGeometryLoading, setGeometryError } = useViewportStore();

  const handleLoad = React.useCallback(() => {
    setGeometryLoading(false);
  }, [setGeometryLoading]);

  const handleError = React.useCallback(
    (err: string) => {
      setGeometryError(err);
    },
    [setGeometryError],
  );

  return (
    <>
      <ambientLight intensity={0.6} />
      <directionalLight position={[5, 10, 5]} intensity={1.2} castShadow />
      <directionalLight position={[-5, -5, -5]} intensity={0.3} />

      <Suspense fallback={null}>
        <GeometryMesh url={geometryUrl} onLoad={handleLoad} onError={handleError} />
        <VladOverlay verdict={vladVerdict} failCount={vladFailCount} />
      </Suspense>

      <OrbitControls
        makeDefault
        enablePan
        enableZoom
        enableRotate
        dampingFactor={0.05}
        rotateSpeed={0.8}
      />

      <gridHelper args={[200, 40, '#444', '#333']} />
      <axesHelper args={[30]} />
    </>
  );
}

// ---------------------------------------------------------------------------
// Loading / error placeholder (shown outside Canvas)
// ---------------------------------------------------------------------------

function GeometryPlaceholder({ message }: { message: string }) {
  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#888',
        fontSize: 14,
        fontFamily: 'monospace',
        background: '#1a1a1a',
      }}
    >
      {message}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Viewport3D — public component
// ---------------------------------------------------------------------------

export interface Viewport3DProps {
  /** Optional explicit width/height (defaults to 100%/100%). */
  width?: number | string;
  height?: number | string;
}

export function Viewport3D({ width = '100%', height = '100%' }: Viewport3DProps) {
  const {
    resolvedGeometryUrl,
    isGeometryLoading,
    geometryError,
    activeModuleId,
    setGeometryLoading,
  } = useViewportStore();

  const activeModule = useModuleStore((s) => s.activeModule());

  const geometryUrl = resolvedGeometryUrl();

  // Notify store when a new URL is about to be fetched
  useEffect(() => {
    if (geometryUrl) {
      setGeometryLoading(true);
    }
  }, [geometryUrl, setGeometryLoading]);

  // Derive VLAD overlay state from the active module's summary
  let vladVerdict: VladVerdict = 'none';
  let vladFailCount: number | undefined;
  if (activeModule?.vladSummary) {
    vladVerdict = activeModule.vladSummary.verdict;
    vladFailCount = activeModule.vladSummary.failCount;
  } else if (activeModuleId) {
    vladVerdict = 'pending';
  }

  if (!geometryUrl) {
    return (
      <div style={{ width, height }}>
        <GeometryPlaceholder message="No module selected — pick one from the sidebar." />
      </div>
    );
  }

  if (geometryError) {
    return (
      <div style={{ width, height }}>
        <GeometryPlaceholder message={`Geometry error: ${geometryError}`} />
      </div>
    );
  }

  return (
    <div style={{ width, height, position: 'relative', background: '#1a1a1a' }}>
      {isGeometryLoading && (
        <div
          style={{
            position: 'absolute',
            top: 8,
            left: 8,
            color: '#aaa',
            fontSize: 12,
            fontFamily: 'monospace',
            zIndex: 10,
          }}
        >
          Loading geometry…
        </div>
      )}

      <Canvas
        shadows
        camera={{ position: [80, 60, 80], fov: 45, near: 0.1, far: 10000 }}
        gl={{ antialias: true }}
        style={{ width: '100%', height: '100%' }}
      >
        <Scene
          geometryUrl={geometryUrl}
          vladVerdict={vladVerdict}
          vladFailCount={vladFailCount}
        />
      </Canvas>
    </div>
  );
}

export default Viewport3D;
