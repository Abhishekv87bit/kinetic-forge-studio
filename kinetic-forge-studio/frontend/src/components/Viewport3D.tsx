import { useRef, useState, useEffect, useCallback } from "react";
import { Canvas, useLoader, useThree, type ThreeEvent } from "@react-three/fiber";
import { OrbitControls, Grid } from "@react-three/drei";
import { GLTFLoader } from "three-stdlib";
import * as THREE from "three";
import { useViewportStore } from "../stores/viewportStore";
import ViewportToolbar, { type ViewMode } from "./ViewportToolbar";

const API_BASE = "http://localhost:8100/api";

/** Fallback cube shown while geometry is loading or on error */
function FallbackCube() {
    return (
        <mesh>
            <boxGeometry args={[1, 1, 1]} />
            <meshStandardMaterial color="#333" wireframe />
        </mesh>
    );
}

/** Loading indicator overlay */
function LoadingOverlay() {
    return (
        <div style={{
            position: "absolute", top: 0, left: 0, right: 0, bottom: 0,
            display: "flex", alignItems: "center", justifyContent: "center",
            pointerEvents: "none", zIndex: 10,
        }}>
            <div style={{
                background: "rgba(0,0,0,0.7)", padding: "12px 24px",
                borderRadius: 8, color: "#aaa", fontSize: 13,
            }}>
                Loading geometry...
            </div>
        </div>
    );
}

/** Error overlay */
function ErrorOverlay({ message }: { message: string }) {
    return (
        <div style={{
            position: "absolute", top: 8, left: 8, right: 8,
            background: "rgba(180,40,40,0.8)", padding: "8px 12px",
            borderRadius: 4, color: "#fff", fontSize: 12, zIndex: 10,
        }}>
            {message}
        </div>
    );
}

/**
 * Camera controller that responds to preset view changes.
 * Lives inside the Canvas to access useThree().
 */
function CameraController({ targetPosition }: { targetPosition: [number, number, number] | null }) {
    const { camera } = useThree();

    useEffect(() => {
        if (!targetPosition) return;
        const [x, y, z] = targetPosition;
        // Scale the preset direction by the camera's current distance to maintain zoom level
        const currentDist = camera.position.length();
        const dir = new THREE.Vector3(x, y, z).normalize();
        const scaledPos = dir.multiplyScalar(Math.max(currentDist, 5));

        camera.position.set(scaledPos.x, scaledPos.y, scaledPos.z);
        camera.lookAt(0, 0, 0);
        camera.updateProjectionMatrix();
    }, [targetPosition, camera]);

    return null;
}

/**
 * Applies view mode (solid, wireframe, xray) to all meshes in the scene.
 * Lives inside the Canvas.
 */
function ViewModeController({ scene, viewMode, highlightedUuid }: {
    scene: THREE.Object3D | null;
    viewMode: ViewMode;
    highlightedUuid: string | null;
}) {
    const originalMaterials = useRef<Map<string, THREE.Material | THREE.Material[]>>(new Map());

    // Store originals on first load
    useEffect(() => {
        if (!scene) return;
        scene.traverse((child) => {
            if (child instanceof THREE.Mesh && !originalMaterials.current.has(child.uuid)) {
                // Clone the material so we have a clean original
                if (Array.isArray(child.material)) {
                    originalMaterials.current.set(child.uuid, child.material.map((m: THREE.Material) => m.clone()));
                } else {
                    originalMaterials.current.set(child.uuid, child.material.clone());
                }
            }
        });
    }, [scene]);

    // Apply view mode
    useEffect(() => {
        if (!scene) return;

        scene.traverse((child) => {
            if (!(child instanceof THREE.Mesh)) return;

            // Skip highlighted mesh — it keeps its highlight material
            if (child.uuid === highlightedUuid) return;

            const original = originalMaterials.current.get(child.uuid);
            if (!original) return;

            if (viewMode === "solid") {
                // Restore original material
                child.material = Array.isArray(original)
                    ? original.map((m: THREE.Material) => m.clone())
                    : original.clone();
            } else if (viewMode === "wireframe") {
                const mat = new THREE.MeshStandardMaterial({
                    color: 0x4a9eff,
                    wireframe: true,
                });
                child.material = mat;
            } else if (viewMode === "xray") {
                const mat = new THREE.MeshStandardMaterial({
                    color: 0x4a9eff,
                    transparent: true,
                    opacity: 0.25,
                    depthWrite: false,
                    side: THREE.DoubleSide,
                });
                child.material = mat;
            }
        });
    }, [scene, viewMode, highlightedUuid]);

    return null;
}

/**
 * Component that loads a GLB from the backend and renders it.
 * Handles click-to-select with raycasting via R3F's built-in event system.
 */
function GeometryScene({ url, viewMode }: { url: string; viewMode: ViewMode }) {
    const gltf = useLoader(GLTFLoader, url);
    const groupRef = useRef<THREE.Group>(null);
    const { selectMesh } = useViewportStore();
    const [highlightedUuid, setHighlightedUuid] = useState<string | null>(null);

    // Fit camera to loaded scene
    const { camera } = useThree();
    useEffect(() => {
        if (!gltf.scene) return;
        const box = new THREE.Box3().setFromObject(gltf.scene);
        const size = box.getSize(new THREE.Vector3());
        const center = box.getCenter(new THREE.Vector3());
        const maxDim = Math.max(size.x, size.y, size.z);
        const distance = maxDim * 2.5;

        if (camera instanceof THREE.PerspectiveCamera) {
            camera.position.set(
                center.x + distance * 0.7,
                center.y + distance * 0.7,
                center.z + distance * 0.7,
            );
            camera.lookAt(center);
            camera.updateProjectionMatrix();
        }
    }, [gltf, camera]);

    // Apply highlight to selected mesh
    useEffect(() => {
        if (!gltf.scene) return;
        gltf.scene.traverse((child) => {
            if (child instanceof THREE.Mesh) {
                if (child.uuid === highlightedUuid) {
                    child.material = new THREE.MeshStandardMaterial({
                        color: 0x4a9eff,
                        emissive: 0x1a3a6e,
                        emissiveIntensity: 0.3,
                        wireframe: false,
                    });
                }
            }
        });
    }, [highlightedUuid, gltf]);

    const handleClick = useCallback((e: ThreeEvent<MouseEvent>) => {
        e.stopPropagation();
        const mesh = e.object;
        if (mesh instanceof THREE.Mesh) {
            const box = new THREE.Box3().setFromObject(mesh);
            const meshName = mesh.name || mesh.parent?.name || "unnamed";
            setHighlightedUuid(mesh.uuid);
            selectMesh({
                name: meshName,
                uuid: mesh.uuid,
                boundingBox: {
                    min: [box.min.x, box.min.y, box.min.z],
                    max: [box.max.x, box.max.y, box.max.z],
                },
                vertexCount: mesh.geometry?.attributes?.position?.count ?? 0,
                faceCount: mesh.geometry?.index
                    ? mesh.geometry.index.count / 3
                    : (mesh.geometry?.attributes?.position?.count ?? 0) / 3,
            });
        }
    }, [selectMesh]);

    const handleMissed = useCallback(() => {
        setHighlightedUuid(null);
        selectMesh(null);
    }, [selectMesh]);

    return (
        <group ref={groupRef}>
            <ViewModeController
                scene={gltf.scene}
                viewMode={viewMode}
                highlightedUuid={highlightedUuid}
            />
            <primitive
                object={gltf.scene}
                onClick={handleClick}
                onPointerMissed={handleMissed}
            />
        </group>
    );
}

interface Viewport3DProps {
    projectId?: string;
}

export default function Viewport3D({ projectId }: Viewport3DProps) {
    const { loading, error, setLoading, setError, geometryVersion } = useViewportStore();
    const [geometryUrl, setGeometryUrl] = useState<string | null>(null);
    const [cameraTarget, setCameraTarget] = useState<[number, number, number] | null>(null);
    const [viewMode, setViewMode] = useState<ViewMode>("solid");

    useEffect(() => {
        if (!projectId) {
            setGeometryUrl(null);
            return;
        }

        setLoading(true);
        setError(null);

        const controller = new AbortController();
        fetch(`${API_BASE}/projects/${projectId}/geometry`, { signal: controller.signal })
            .then((res) => {
                if (!res.ok) throw new Error(`Failed to load geometry: ${res.status}`);
                return res.blob();
            })
            .then((blob) => {
                const url = URL.createObjectURL(blob);
                setGeometryUrl((prev) => {
                    if (prev) URL.revokeObjectURL(prev);
                    return url;
                });
                setLoading(false);
            })
            .catch((err) => {
                if (err.name !== "AbortError") {
                    setError(err.message);
                    setLoading(false);
                }
            });

        return () => {
            controller.abort();
        };
    }, [projectId, geometryVersion, setLoading, setError]);

    // Cleanup blob URL on unmount
    useEffect(() => {
        return () => {
            if (geometryUrl) URL.revokeObjectURL(geometryUrl);
        };
    }, [geometryUrl]);

    const handleSetView = useCallback((position: [number, number, number]) => {
        // Use a new array reference each time to trigger the effect
        setCameraTarget([...position]);
    }, []);

    return (
        <div style={{ position: "relative", width: "100%", height: "100%" }}>
            {loading && <LoadingOverlay />}
            {error && <ErrorOverlay message={error} />}
            <ViewportToolbar
                onSetView={handleSetView}
                viewMode={viewMode}
                onSetViewMode={setViewMode}
            />
            <Canvas camera={{ position: [3, 3, 3], fov: 50 }}>
                <ambientLight intensity={0.5} />
                <directionalLight position={[10, 10, 10]} intensity={0.8} />
                <directionalLight position={[-5, 5, -5]} intensity={0.3} />

                <CameraController targetPosition={cameraTarget} />

                {geometryUrl ? (
                    <GeometryScene url={geometryUrl} viewMode={viewMode} />
                ) : (
                    <FallbackCube />
                )}

                <OrbitControls
                    enableDamping
                    dampingFactor={0.05}
                    rotateSpeed={0.5}
                    panSpeed={0.5}
                    zoomSpeed={0.8}
                />
                <Grid
                    infiniteGrid
                    cellSize={1}
                    sectionSize={5}
                    fadeDistance={30}
                    cellColor="#333"
                    sectionColor="#555"
                />
            </Canvas>
        </div>
    );
}
