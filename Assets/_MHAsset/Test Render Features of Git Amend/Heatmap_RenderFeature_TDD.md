# Heatmap Render Feature Documentation

## Overview
The Heatmap Render Feature is a Unity URP (Universal Render Pipeline) custom render feature that generates a dynamic heatmap visualization using compute shaders. It simulates the presence of entities (enemies) moving in 2D space and creates a visual representation of their influence areas.

## Components

### 1. HeatmapRendererFeature
The main renderer feature class that integrates with Unity's URP.

Key features:
- Implements `ScriptableRendererFeature`
- Manages the render pass lifecycle
- Provides singleton access through `Instance`
- Handles compute shader resource management

### 2. HeatmapPass
The core render pass that performs the computation:
- Resolution: 256x256
- Supports up to 64 entities
- Uses compute shader for parallel processing
- Implements modern render graph API

### 3. Compute Shader (HeatmapCompute.compute)
Performs the actual heatmap calculation:
- Thread group size: 8x8x1
- Takes enemy positions as input
- Calculates heat influence with linear falloff
- Radius of influence: 20 units
- Output: Single-channel (R32_SFloat) texture

### 4. Visualizer (HeatmapVisualizer.cs)
UI component for displaying the heatmap:
- Converts render texture to UI sprite
- Updates in real-time
- Supports material-based rendering

## Technical Details

### Data Flow
1. Enemy positions are updated using Perlin noise for smooth movement
2. Positions are uploaded to a GPU buffer
3. Compute shader processes the data in parallel
4. Results are written to a render texture
5. Visualizer displays the texture through UI system

### Memory Management
- Uses `RTHandle` for efficient render texture management
- Properly handles resource cleanup
- Implements buffer resizing when needed

### Performance Considerations
- Compute shader dispatch size optimized for 8x8 thread groups
- Single-pass rendering
- Efficient buffer updates
- Minimal texture format (R32_SFloat) for heat values

## Requirements
- Unity URP (Universal Render Pipeline)
- Compute shader support on target platform
- GPU with compute capability

## Usage

### Setup
1. Add the HeatmapRendererFeature to your URP renderer
2. Assign the compute shader in the inspector
3. Add HeatmapVisualizer to a UI Image component
4. Assign a material that can display the heatmap texture

### Customization
You can modify:
- Heatmap resolution (width/height)
- Number of entities (enemyCount)
- Heat influence radius and falloff in compute shader
- Update frequency and movement patterns

## Implementation Notes
- Uses modern Unity rendering features (RenderGraph API)
- Thread-safe and efficient resource management
- Automatic cleanup of GPU resources
- Real-time updates with smooth entity movement

## Limitations
- Fixed resolution (256x256)
- Maximum 64 entities
- Requires compute shader support
- Single-channel output (grayscale heatmap) 