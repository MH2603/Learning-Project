// Custom Universal Render Pipeline (URP) feature that generates a dynamic heatmap using compute shaders
// This feature simulates and visualizes enemy positions using Perlin noise for movement
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using UnityEngine.Experimental.Rendering;

public class HeatmapRendererFeature : ScriptableRendererFeature {
    // Singleton instance for easy access from other components
    public static HeatmapRendererFeature Instance { get; private set; }

    // Custom render pass that handles the compute shader execution and heatmap generation
    class HeatmapPass : ScriptableRenderPass {
        // Reference to the compute shader that generates the heatmap
        ComputeShader computeShader;
        int kernel;

        // Buffer to store enemy positions that will be sent to the GPU
        GraphicsBuffer enemyBuffer;
        Vector2[] enemyPositions;
        int enemyCount = 64;

        // Render texture handle for the heatmap output
        RTHandle heatmapHandle;
        int width = 256, height = 256;

        // Public accessor for the generated heatmap texture
        public RTHandle Heatmap => heatmapHandle;

        public void Setup(ComputeShader cs) {
            computeShader = cs;
            kernel = cs.FindKernel("CSMain");

            // Create or recreate the heatmap render texture if needed
            if (heatmapHandle == null || heatmapHandle.rt.width != width || heatmapHandle.rt.height != height) {
                heatmapHandle?.Release();
                var desc = new RenderTextureDescriptor(width, height, GraphicsFormat.R32_SFloat, 0) {
                    enableRandomWrite = true,
                    msaaSamples = 1,
                    sRGB = false,
                    useMipMap = false
                };
                heatmapHandle = RTHandles.Alloc(desc, name: "_HeatmapRT");
            }

            // Create or recreate the enemy positions buffer if needed
            if (enemyBuffer == null || enemyBuffer.count != enemyCount) {
                enemyBuffer?.Release();
                enemyBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, enemyCount, sizeof(float) * 2);
                enemyPositions = new Vector2[enemyCount];
            }
        }

        // Data structure for passing parameters to the render graph
        class PassData {
            public ComputeShader compute;
            public int kernel;
            public TextureHandle output;
            public Vector2 texSize;
            public BufferHandle enemyHandle;
            public int enemyCount;
        }

        public override void RecordRenderGraph(RenderGraph graph, ContextContainer context) {
            // Update enemy positions using Perlin noise for smooth movement
            for (int i = 0; i < enemyCount; i++) {
                float t = Time.time * 0.5f + i * 0.1f;
                float x = Mathf.PerlinNoise(t, i * 1.31f) * width;
                float y = Mathf.PerlinNoise(i * 0.91f, t) * height;
                enemyPositions[i] = new Vector2(x, y);
            }
            
            // Upload updated enemy positions to the GPU buffer
            enemyBuffer.SetData(enemyPositions);

            // Import resources into the render graph
            TextureHandle texHandle = graph.ImportTexture(heatmapHandle);
            BufferHandle enemyHandle = graph.ImportBuffer(enemyBuffer);

            // Set up the compute pass
            using IComputeRenderGraphBuilder builder = graph.AddComputePass("HeatmapPass", out PassData data);
            data.compute = computeShader;
            data.kernel = kernel;
            data.output = texHandle;
            data.enemyHandle = enemyHandle;
            data.enemyCount = enemyCount;

            // Declare resource usage
            builder.UseTexture(texHandle, AccessFlags.Write);
            builder.UseBuffer(enemyHandle, AccessFlags.Read);

            // Define the compute shader dispatch
            builder.SetRenderFunc((PassData d, ComputeGraphContext ctx) => {
                ctx.cmd.SetComputeIntParam(d.compute, "enemyCount", d.enemyCount);
                ctx.cmd.SetComputeBufferParam(d.compute, d.kernel, "enemyPositions", d.enemyHandle);
                ctx.cmd.SetComputeTextureParam(d.compute, d.kernel, "heatmapTexture", d.output);
                ctx.cmd.DispatchCompute(d.compute, d.kernel, Mathf.CeilToInt(width / 8f), Mathf.CeilToInt(height / 8f), 1);
            });
        }

        // Clean up resources when the pass is destroyed
        public void Cleanup() {
            heatmapHandle?.Release();
            heatmapHandle = null;

            enemyBuffer?.Release();
            enemyBuffer = null;
        }
    }

    // Reference to the compute shader asset
    [SerializeField] ComputeShader computeShader;
    HeatmapPass pass;

    public override void Create() {
        // Initialize the render pass
        pass = new HeatmapPass {
            renderPassEvent = RenderPassEvent.BeforeRendering
        };
        Instance = this;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        // Skip if compute shaders aren't supported or shader is missing
        if (!SystemInfo.supportsComputeShaders || computeShader == null)
            return;

        pass.Setup(computeShader);
        renderer.EnqueuePass(pass);
    }

    protected override void Dispose(bool disposing) {
        // Clean up resources when the feature is disposed
        pass?.Cleanup();
    }

    // Public accessor for the heatmap texture
    public RTHandle GetHeatmapTexture() => pass?.Heatmap;
}