using System;
using UnityEngine;

// This component requires the GameObject to have both a MeshFilter and a MeshRenderer component.
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class SimpleProceduralMesh : MonoBehaviour
{
    // Unity calls this method when the script is enabled.
    void OnEnable()
    {
        // Create a new Mesh instance and assign it a name for identification in the editor.
        var mesh = new Mesh
        {
            name = "Procedural Mesh" // Name of the mesh for easier debugging and identification.
        };

        // Define the vertices of the mesh. These are the points in 3D space that make up the shape.
        mesh.vertices = new Vector3[]
        {
            Vector3.zero,               // Bottom-left corner (0, 0, 0)
            Vector3.right,              // Bottom-right corner (1, 0, 0)
            Vector3.up,                 // Top-left corner (0, 1, 0)
            new Vector3(1f, 1f)         // Top-right corner (1, 1, 0)
        };

        // Define the triangles of the mesh. Each triangle is defined by three vertex indices.
        // The order of the indices determines the front face of the triangle (clockwise winding).
        mesh.triangles = new int[]
        {
            0, 2, 1, // First triangle (bottom-left, top-left, bottom-right)
            1, 2, 3  // Second triangle (bottom-right, top-left, top-right)
        };

        // Define the normals for each vertex. Normals are used for lighting calculations.
        // In this case, all normals point backward (negative Z-axis).
        mesh.normals = new Vector3[]
        {
            Vector3.back, // Normal for vertex 0
            Vector3.back, // Normal for vertex 1
            Vector3.back, // Normal for vertex 2
            Vector3.back  // Normal for vertex 3
        };

        // Define the UV coordinates for each vertex. UVs are used for texture mapping.
        // These map the vertices to positions on a 2D texture.
        mesh.uv = new Vector2[]
        {
            Vector2.zero,  // UV for vertex 0 (bottom-left of the texture)
            Vector2.right, // UV for vertex 1 (bottom-right of the texture)
            Vector2.up,    // UV for vertex 2 (top-left of the texture)
            Vector2.one    // UV for vertex 3 (top-right of the texture)
        };

        // Define the tangents for each vertex. Tangents are used for advanced lighting effects like normal mapping.
        // The fourth component (w) determines the handedness of the tangent (usually -1 or 1).
        // Each vertex need to define a TBN space, which is a matrix that contains the tangent, bitangent and normal.
        // So W of tangent is used to determine the direction of the bitangent by cross with normal.
        mesh.tangents = new Vector4[]
        {
            new Vector4(1f, 0f, 0f, -1f), // Tangent for vertex 0
            new Vector4(1f, 0f, 0f, -1f), // Tangent for vertex 1
            new Vector4(1f, 0f, 0f, -1f), // Tangent for vertex 2
            new Vector4(1f, 0f, 0f, -1f)  // Tangent for vertex 3
        };

        // Assign the created mesh to the MeshFilter component of the GameObject.
        // This makes the mesh visible in the scene.
        GetComponent<MeshFilter>().mesh = mesh;
    }
}