// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Custom/Textured With Detail" {


	// Shader properties are declared in a separate block. Add it at the top of the shader.
	Properties {

		// The property name must be followed by a string and a type, in parenthesis, as if you're invoking a method. 
		// The string is used to label the property in the material inspector. In this case, the type is Color.
		_Tint("Tint", Color) = (1,1,1,1)

		_MainTex ("Texture", 2D) = "white" {} // {} not function -> to ignore bug
		_DetailTex ("Detail Texture", 2D) = "gray" {}
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

			// We have to indicate the start of our code with the CGPROGRAM keyword. 
			// And we have to terminate with the ENDCG keyword.
			CGPROGRAM

			// Shaders consist of two programs : vertex and fragment programs
			// The vertex program is responsible for processing the vertex data of a mesh. This includes the conversion from object space to display space, just like we did in part 1, Matrices. 
			// The fragment program is responsible for coloring individual pixels that lie inside the mesh's triangles.
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			// But shaders don't have classes. They're just one big file with all the code, without the grouping provided by classes or namespaces.
			// Fortunately, we can split the code into multiple files. You can use the #include directive to load a different file's contents into the current file.
			#include "UnityCG.cginc"

			// To actually use the property, we have to add a variable to the shader code. 
			// Its name has to exactly match the property name, so it'll be _Tint.
			float4 _Tint;
			sampler2D _MainTex, _DetailTex;
			float4 _MainTex_ST, _DetailTex_ST; // ST is Scale and Translation -> use to titling and offset

			struct Interpolators {
				float4 position : SV_POSITION; // position of clip space
				float2 uv : TEXCOORD0;
				float2 uvDetail : TEXCOORD1;
				// float3 localPosition : TEXCOORD0;
			};

			struct VertexData {
				float4 position : POSITION; // position of object-space
				float2 uv : TEXCOORD0; // uv coordition of vertex which is included in mesh
			};

			// Ver 01
			// MyVertexProgram is method of Vertex program -> use to define pos of vertex
			// To do so, we need to know the object-space position of the vertex. 
			// We can access it by adding a variable with the POSITION semantic to our function
			// float4 MyVertexProgram (
			// 	float4 position : POSITION,
			// 	out float3 localPosition : TEXCOORD0
			// ) : SV_POSITION 
			// {
			// 	// return position;

			// 	// To pass the data through the vertex program, copy the X, Y, and Z components from position to localPosition.
			// 	localPosition = position.xyz;
			// 	return UnityObjectToClipPos(position); // return mul(UNITY_MATRIX_MVP, position);
			// }



			// Ver 02: set data for Interpolators
			// Interpolators MyVertexProgram (
			// 	float4 position : POSITION,
			// 	float2 uv = TEXCOORD0
			// ) 
			// {
			// 	Interpolators i;
			// 	i.localPosition = position.xyz;
			// 	i.position = UnityObjectToClipPos(position);
			// 	return i;
			// }


			// ver 03: use VertexData
			Interpolators MyVertexProgram (VertexData v) {
				Interpolators i;
				// i.localPosition = v.position.xyz;
				i.position = UnityObjectToClipPos(v.position);
				// i.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
				i.uv = TRANSFORM_TEX(v.uv, _MainTex); // TRANSFORM_TEX(v.uv, _MainTex) = v.uv * _MainTex_ST.xy + _MainTex_ST.zw
				i.uvDetail = TRANSFORM_TEX(v.uv, _DetailTex);
				return i;
			}

			// Ver 01
			// MyFragmentProgram is method of fragment program -> use to define triangles.
			// the output of the vertex program is used as input for the fragment program. 
			// This suggests that the fragment program should get a parameter that matches the vertex program's output
			// float4 MyFragmentProgram (
			// 	float4 position : SV_POSITION, 
			// 	float3 localPosition: TEXCOORD0 
			// 	) : SV_TARGET 
			// {
				
			// 	// return float4(1, 1, 0, 1);
			// 	// return _Tint;

			// 	return float4(localPosition, 1);
			// }

			// Ver 02: use uv to fix color
			// float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
			// 	return float4(i.uv, 1, 1);
			// }

			// Ver 03
			// float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
			// 	return tex2D(_MainTex, i.uv) * _Tint;
			// }

			// Ver 04
			float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
				float4 color = tex2D(_MainTex, i.uv) * _Tint;
				color *= tex2D(_DetailTex, i.uvDetail) * unity_ColorSpaceDouble;
				return color;
			}

			ENDCG
		}
	}
}