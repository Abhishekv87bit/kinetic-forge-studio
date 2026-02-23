import { Canvas } from "@react-three/fiber";
import { OrbitControls, Grid } from "@react-three/drei";

function TestCube() {
    return (
        <mesh>
            <boxGeometry args={[1, 1, 1]} />
            <meshStandardMaterial color="#4a9eff" />
        </mesh>
    );
}

export default function Viewport3D() {
    return (
        <Canvas camera={{ position: [3, 3, 3], fov: 50 }}>
            <ambientLight intensity={0.4} />
            <directionalLight position={[5, 5, 5]} intensity={0.8} />
            <TestCube />
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
    );
}
