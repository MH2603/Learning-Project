using System.IO;

namespace MH.Editor
{
    using UnityEngine;
    using UnityEditor;

    public class VertexAnimationTextureBakerWindow : EditorWindow
    {
        private Animator animator;
        private SkinnedMeshRenderer skin;
        private string savePath;

        [MenuItem("Tool/Vertex Animation Texture Baker")]
        public static void ShowWindow()
        {
            GetWindow<VertexAnimationTextureBakerWindow>("Vertex Animation Texture Baker");
        }

        private void OnGUI()
        {
            GUILayout.Label("Vertex Animation Texture Baker", EditorStyles.boldLabel);

            animator = (Animator)EditorGUILayout.ObjectField("Animator", animator, typeof(Animator), true);
            skin = (SkinnedMeshRenderer)EditorGUILayout.ObjectField("Skinned Mesh Renderer", skin, typeof(SkinnedMeshRenderer), true);
            savePath = EditorGUILayout.TextField("Save Path", savePath);

            if (GUILayout.Button("Choose Save Path"))
            {
                string path = EditorUtility.OpenFolderPanel("Choose Save Path", "Assets", "");
                if (!string.IsNullOrEmpty(path))
                {
                    if (path.StartsWith(Application.dataPath))
                    {
                        savePath = "Assets" + path.Substring(Application.dataPath.Length);
                    }
                    else
                    {
                        Debug.LogWarning("Please choose a path within the Assets folder.");
                    }
                }
            }

            if (GUILayout.Button("Bake Animation"))
            {
                if (animator != null && skin != null && !string.IsNullOrEmpty(savePath))
                {
                    // Call your baking function here
                    var textures = VertexBakerUtil.BakeAnimationIntoVertex(skin, animator);
                    // Save textures to the specified path
                    foreach (var texture in textures)
                    {
                        // var bytes = texture.EncodeToPNG();
                        // System.IO.File.WriteAllBytes(System.IO.Path.Combine(savePath, texture.name + ".asset"), bytes);
                        
                        AssetDatabase.CreateAsset(texture, Path.Combine(savePath, texture.name + ".asset"));
                        AssetDatabase.SaveAssets();
                    }
                    
                    
                    AssetDatabase.Refresh();
                    Debug.Log("Baking completed and textures saved.");
                }
                else
                {
                    Debug.LogWarning("Please assign all fields before baking.");
                }
            }
        }
    }
}