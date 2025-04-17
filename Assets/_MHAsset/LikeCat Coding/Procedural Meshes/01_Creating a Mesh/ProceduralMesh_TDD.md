# Technical Design Document: Advanced Multi-Stream Procedural Mesh

Reference Tutorial: [Creating a Mesh - Catlike Coding](https://catlikecoding.com/unity/tutorials/procedural-meshes/creating-a-mesh/)

## Overview
This document details the implementation of procedural mesh generation in Unity using two different approaches: the simple approach (`SimpleProceduralMesh`) and the advanced approach (`AdvancedMultiStreamProceduralMesh`). Both classes demonstrate how to create a quad mesh programmatically, but with different methodologies and performance considerations.

## Class Comparison

### SimpleProceduralMesh
#### Implementation Approach
- Uses standard C# arrays and Unity's basic mesh API
- Direct assignment of mesh properties (vertices, triangles, normals, UVs, tangents)
- More straightforward and easier to understand
- Suitable for simple, non-performance-critical mesh generation

#### Code Structure
```csharp
mesh.vertices = new Vector3[] { ... }
mesh.triangles = new int[] { ... }
mesh.normals = new Vector3[] { ... }
mesh.uv = new Vector2[] { ... }
mesh.tangents = new Vector4[] { ... }
```

### AdvancedMultiStreamProceduralMesh
#### Implementation Approach
- Uses Unity's Native Arrays and modern mesh API
- Multi-stream vertex attributes
- More complex but better performance
- Suitable for high-performance mesh generation

#### Code Structure
```csharp
Mesh.MeshDataArray meshDataArray = Mesh.AllocateWritableMeshData(1);
// Configure vertex attributes and streams
// Write data directly to native arrays
```

## Why Native Arrays?

### Performance Benefits
1. **Memory Efficiency**
   - Native arrays are allocated in native memory (C++ side)
   - Reduces garbage collection pressure
   - Better memory layout for performance

2. **Direct Memory Access**
   - No managed-to-native conversion overhead
   - Faster data transfer between CPU and GPU
   - More efficient for large mesh operations

3. **Multi-threading Support**
   - Can be safely used across multiple threads
   - Enables parallel mesh generation
   - Better scalability for complex mesh operations

### Implementation Details

#### Vertex Attribute Streams
The advanced implementation separates vertex attributes into different streams:
1. **Stream 0**: Positions (float3)
2. **Stream 1**: Normals (float3)
3. **Stream 2**: Tangents (float4)
4. **Stream 3**: UV Coordinates (float2)

This separation allows for:
- Better memory alignment
- More efficient GPU data transfer
- Potential for streaming mesh data

## Key Technical Differences

### Memory Management
1. **Simple Approach**
   ```csharp
   // Managed arrays, handled by garbage collector
   mesh.vertices = new Vector3[4];
   ```

2. **Advanced Approach**
   ```csharp
   // Native arrays, explicit allocation and disposal
   NativeArray<float3> positions = meshData.GetVertexData<float3>();
   // Must be disposed properly
   ```

### Data Layout
1. **Simple Approach**
   - Single interleaved vertex buffer
   - All attributes stored together
   - Less control over memory layout

2. **Advanced Approach**
   - Separate streams for each attribute
   - Better cache coherency
   - More flexible memory layout
   - Better alignment for SIMD operations

## Best Practices

### When to Use Simple Approach
- Prototyping and learning
- Simple mesh generation needs
- Non-performance critical applications
- When code readability is priority

### When to Use Advanced Approach
- High-performance requirements
- Large mesh generation
- Real-time mesh modification
- When working with jobs system
- When memory efficiency is crucial

## Implementation Notes

### Memory Safety
- Native arrays require proper disposal
- Use using statements or explicit Dispose calls
- Important to prevent memory leaks

### Performance Tips
1. Pre-calculate vertex counts
2. Use appropriate index formats (UInt16 vs UInt32)
3. Set bounds correctly for culling
4. Use MeshUpdateFlags appropriately

## Code Example Comparison

### Vertex Definition
**Simple:**
```csharp
mesh.vertices = new Vector3[] {
    Vector3.zero,
    Vector3.right,
    Vector3.up,
    new Vector3(1f, 1f)
};
```

**Advanced:**
```csharp
NativeArray<float3> positions = meshData.GetVertexData<float3>();
positions[0] = 0f;
positions[1] = right();
positions[2] = up();
positions[3] = float3(1f, 1f, 0f);
```

## Conclusion
While both approaches achieve the same result, the advanced implementation offers better performance and memory efficiency at the cost of increased complexity. Choose the appropriate implementation based on your project's specific needs and performance requirements. 