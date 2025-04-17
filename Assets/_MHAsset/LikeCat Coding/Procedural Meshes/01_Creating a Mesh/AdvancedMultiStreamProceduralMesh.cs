using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Mathematics;
using static Unity.Mathematics.math;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class AdvancedMultiStreamProceduralMesh : MonoBehaviour {

    
    void OnEnable () {
        
        // Each vertex of our mesh has four attributes: a position, a normal, a tangent, and a set of texture coordinates
        int vertexAttributeCount = 4;
        
        int vertexCount = 4;
        
        int triangleIndexCount = 6;

        
        // To write into native mesh data we have to first allocate it. We do this by invoking the static Mesh.AllocateWritableMeshData method
        // and passing the number of meshes we want to allocate. This will return a NativeArray of Mesh.MeshDataArray.
        Mesh.MeshDataArray meshDataArray = Mesh.AllocateWritableMeshData(1);
        
        //To fill the mesh data we have to retrieve the single element from the array,
        //keeping track of it via a variable. Its type is Mesh.MeshData.
        Mesh.MeshData meshData = meshDataArray[0];
        
        // This array is later populated with specific VertexAttributeDescriptor instances, each describing a vertex attribute (e.g., position, normal, tangent, and texture coordinates).
        // After the attributes are defined, the array is used to configure the vertex buffer of the mesh, and the NativeArray is disposed of to free the allocated memory.
        var vertexAttributes = new NativeArray<VertexAttributeDescriptor>(
            vertexAttributeCount, Allocator.Temp,  NativeArrayOptions.UninitializedMemory
        );
        
        vertexAttributes[0] = new VertexAttributeDescriptor(dimension: 3);
        vertexAttributes[1] = new VertexAttributeDescriptor(
            VertexAttribute.Normal, dimension: 3, stream: 1
        );
        vertexAttributes[2] = new VertexAttributeDescriptor(
            VertexAttribute.Tangent, dimension: 4, stream: 2
        );
        vertexAttributes[3] = new VertexAttributeDescriptor(
            VertexAttribute.TexCoord0, dimension: 2, stream: 3
        );
        
        // The vertex streams of the mesh are then allocated by invoking SetVertexBufferParams on the mesh data,
        // with the vertex count and the attribute definitions as arguments.
        // After that we no longer need the attribute definition, so we dispose of it.
        meshData.SetVertexBufferParams(vertexCount, vertexAttributes);
        vertexAttributes.Dispose();
        
        // set data for positions
        NativeArray<float3> positions = meshData.GetVertexData<float3>();
        positions[0] = 0f;
        positions[1] = right();
        positions[2] = up();
        positions[3] = float3(1f, 1f, 0f);
        
        // set data for normals
        NativeArray<float3> normals = meshData.GetVertexData<float3>(1);
        normals[0] = normals[1] = normals[2] = normals[3] = back();

        // set data for tangents
        NativeArray<float4> tangents = meshData.GetVertexData<float4>(2);
        tangents[0] = tangents[1] = tangents[2] = tangents[3] = float4(1f, 0f, 0f, -1f);

        // set data for UVs
        NativeArray<float2> texCoords = meshData.GetVertexData<float2>(3);
        texCoords[0] = 0f;
        texCoords[1] = float2(1f, 0f);
        texCoords[2] = float2(0f, 1f);
        texCoords[3] = 1f;
        
        // set data for indices
        meshData.SetIndexBufferParams(triangleIndexCount, IndexFormat.UInt16);
        NativeArray<ushort> triangleIndices = meshData.GetIndexData<ushort>();
        triangleIndices[0] = 0;
        triangleIndices[1] = 2;
        triangleIndices[2] = 1;
        triangleIndices[3] = 1;
        triangleIndices[4] = 2;
        triangleIndices[5] = 3;
        
        var bounds = new Bounds(new Vector3(0.5f, 0.5f), new Vector3(1f, 1f));
        
        meshData.subMeshCount = 1;
        meshData.SetSubMesh(0, new SubMeshDescriptor(0, triangleIndexCount) {
            bounds = bounds,
            vertexCount = vertexCount
        },  MeshUpdateFlags.DontRecalculateBounds);
        
        var mesh = new Mesh {
            bounds = bounds,
            name = "Procedural Mesh"
        };
        
        // applies the writable mesh data to the mesh and disposes of it.
        // After this, the mesh data cannot be accessed unless retrieved again using Mesh.AcquireReadOnlyMeshData.
        Mesh.ApplyAndDisposeWritableMeshData(meshDataArray, mesh);
        
        GetComponent<MeshFilter>().mesh = mesh;
    }
}