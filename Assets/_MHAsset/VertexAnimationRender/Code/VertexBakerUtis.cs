using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;

namespace MH
{
    public static class VertexBakerUtil
    {
        public static Texture2D[] BakeAnimationIntoVertex(SkinnedMeshRenderer skin, Animator animator)
        {
            var skinTrans = skin.transform;
            skinTrans.position = Vector3.zero;
            skinTrans.rotation = Quaternion.identity;
            skinTrans.localScale = Vector3.one;
            
            List<Texture2D> textures = new List<Texture2D>();
            Mesh mesh = new();
            var animations = animator.runtimeAnimatorController.animationClips;
            for (int i=0; i < animations.Length; i++)
            {
                AnimationClip animationClip = animations[i];

                float frameDur = 1 / animationClip.frameRate;
                List<Vector3> tmpVertices = new List<Vector3>();
                List<Vector3> vertices = new List<Vector3>();
                
                // use vertex count to set horizontal of texture
                int vertexCount = skin.sharedMesh.vertexCount;
                
                // use frame count to set vertical of texture 
                // framerRate : defines the frame rate (FPS - frames per second) at which the animation was created
                // length: the total duration (in seconds) of the AnimationCli
                int frameCount = Mathf.FloorToInt(animationClip.frameRate * animationClip.length) + 1;
                Debug.Log($" Frame count: {frameCount} | fps : {animationClip.frameRate}");

                for (int j = 0; j < frameCount; j++)
                {
                    // Sample the animation at the current frame time
                    animationClip.SampleAnimation(animator.gameObject, j * frameDur);
        
                    // Bake the current state of the SkinnedMeshRenderer into a Mesh
                    skin.BakeMesh(mesh);
        
                    // Get the vertices of the baked mesh
                    mesh.GetVertices(tmpVertices);
                    
                    vertices.AddRange(tmpVertices);
                }
                
                // use to convert world space to object space
                vertices = vertices.Select(pos => skin.transform.InverseTransformPoint(pos)).ToList();

                Texture2D texture = new Texture2D(1000, frameCount, TextureFormat.RGBAHalf, false, true)
                {
                    name = $"{animator.gameObject.name}_{animationClip.name}",
                    filterMode = FilterMode.Bilinear,
                    wrapMode = TextureWrapMode.Repeat,
                    
                };
                
                
                // TextureImporter importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(texture)) as TextureImporter;
                // if (importer != null)
                // {
                //     importer.maxTextureSize = Mathf.Max(vertexCount, frameCount);
                //     AssetDatabase.ImportAsset(AssetDatabase.GetAssetPath(texture), ImportAssetOptions.ForceUpdate);
                // }
                
                texture.Reinitialize(vertexCount, frameCount);
                texture.Apply();
                
                texture.SetPixels(vertices.Select(pos => new Color(pos.x, pos.y, pos.z)).ToArray());
                textures.Add(texture);
                
                // Debug.Log($"{texture.Size()}");
            }
            
            return textures.ToArray();
        }
    }
}