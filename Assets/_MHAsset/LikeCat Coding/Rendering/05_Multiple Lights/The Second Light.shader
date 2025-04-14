// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Custom/My Second Lighting Shader" {


	// Shader properties are declared in a separate block. Add it at the top of the shader.
	Properties {

		// The property name must be followed by a string and a type, in parenthesis, as if you're invoking a method. 
		// The string is used to label the property in the material inspector. In this case, the type is Color.
		_Tint("Tint", Color) = (1,1,1,1)

		_MainTex ("Albedo", 2D) = "white" {} // {} not function -> to ignore bug
		// _SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
		[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
	}


	// You can use these to group multiple shader variants together. 
	// This allows you to provide different sub-shaders for different build platforms or levels of detail. 
	// For example, you could have one sub-shader for desktops and another for mobiles.
	SubShader {

		// The sub-shader has to contain at least one pass. 
		// A shader pass is where an object actually gets rendered. 
		// We'll use one pass, but it's possible to have more. 
		// Having more than one pass means that the object gets rendered multiple times, which is required for a lot of effects.
		Pass {

			// We have to use the ForwardBase pass. 
			// This is the first pass used when rendering something via the forward rendering path. 
			// It gives us access to the main directional light of the scene
			Tags {
				"LightMode" = "ForwardBase"
			}


			// We have to indicate the start of our code with the CGPROGRAM keyword. 
			// And we have to terminate with the ENDCG keyword.
			CGPROGRAM

			// To make sure that Unity selects the best BRDF function, we have to target at least shader level 3.0.
			#pragma target 3.0

			// Shaders consist of two programs : vertex and fragment programs
			// The vertex program is responsible for processing the vertex data of a mesh. This includes the conversion from object space to display space, just like we did in part 1, Matrices. 
			// The fragment program is responsible for coloring individual pixels that lie inside the mesh's triangles.
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "My Lighting.cginc"
			
			ENDCG
		}


		Pass {

			// with this pass -> we can add a lot of light source which like addtication lights
			Tags {
				"LightMode" = "ForwardAdd"
			}

			// The result of such a pass replaced anything that was previously in the frame buffer. 
			// To add to the frame buffer, we'll have to instruct it to use the One One blend mode. This is known as additive blending.
			Blend One One

			// when rendering, GPU will caculate distance form pixel to fragment -> save it into depth buffer
			// So, when add Second light -> GPU will caculate again for same fragment -> it not neccessery -> we need to prevent it by use 'ZWrite Off'
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			// use to cretae multi variants for a pass 
			// in here, this include DIRECTIONAL and POINT for define light_source
			// #pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT 
			#pragma multi_compile _ VERTEXLIGHT_ON

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			// #define POINT // use to ensure attanuation know we use point_light_source
			#include "My Lighting.cginc"

			

			ENDCG
		}
	}
}