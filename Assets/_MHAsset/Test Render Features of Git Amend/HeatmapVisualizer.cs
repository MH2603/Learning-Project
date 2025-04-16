// Visualizes a heatmap texture on a UI Image component
// This script bridges the gap between the render feature and UI visualization
using UnityEngine;
using UnityEngine.UI;

public class HeatmapVisualizer : MonoBehaviour {
    // Material that will receive the heatmap texture
    public Material material;
    // Reference to the UI Image component that will display the heatmap
    Image heatmapImage;

    public bool updateImage;

    void Start() {
        // Get the Image component on this GameObject
        heatmapImage = GetComponent<Image>();
    }

    void Update() {
        // Get the singleton instance of the HeatmapRendererFeature
        var feature = HeatmapRendererFeature.Instance;
        if (feature == null) return;

        // Get the current heatmap texture from the render feature
        var texture = feature.GetHeatmapTexture();
        if (texture != null) {
            // Update the material's base texture with the heatmap
            material.SetTexture("_BaseMap", texture);
        }

        if(!updateImage) return;
        
        // If we have both an image component and a valid texture
        if (heatmapImage && texture != null) {
            // Create a new Texture2D to read the render texture data
            Texture2D texture2D = new Texture2D(texture.rt.width, texture.rt.height, TextureFormat.RFloat, false);

            // Copy the render texture data to our new Texture2D
            RenderTexture.active = texture;
            texture2D.ReadPixels(new Rect(0, 0, texture.rt.width, texture.rt.height), 0, 0);
            texture2D.Apply();
            
            // Create a sprite from the texture and assign it to the UI Image
            heatmapImage.sprite = Sprite.Create(texture2D, new Rect(0, 0, texture.rt.width, texture.rt.height), new Vector2(0.5f, 0.5f));
        }
    }
}
