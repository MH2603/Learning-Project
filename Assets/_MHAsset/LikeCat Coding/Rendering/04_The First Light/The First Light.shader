// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Custom/My First Lighting Shader" {


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

			// But shaders don't have classes. They're just one big file with all the code, without the grouping provided by classes or namespaces.
			// Fortunately, we can split the code into multiple files. You can use the #include directive to load a different file's contents into the current file.
			// #include "UnityCG.cginc" // UnityStandardBRDF.cginc include UnityCG -> we can remove it
			// #include "UnityStandardBRDF.cginc"
			// #include "UnityStandardUtils.cginc"  //Unity has a utility function to take care of the energy conservation
			#include "UnityPBSLighting.cginc" // Unity's standard shaders use a PBS approach

			// To actually use the property, we have to add a variable to the shader code. 
			// Its name has to exactly match the property name, so it'll be _Tint.
			float4 _Tint;
			sampler2D _MainTex;
			float4 _MainTex_ST; // ST is Scale and Translation -> use to titling and offset
			// float4 _SpecularTint;
			float _Metallic;
			float _Smoothness;

			struct Interpolators {
				float4 position : SV_POSITION; // position of clip space
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				// float3 localPosition : TEXCOORD0;
			};

			struct VertexData {
				float4 position : POSITION; // position of object-space
				float3 normal : NORMAL;
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
				i.worldPos = mul(unity_ObjectToWorld, v.position);
				// i.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
				i.uv = TRANSFORM_TEX(v.uv, _MainTex); // TRANSFORM_TEX(v.uv, _MainTex) = v.uv * _MainTex_ST.xy + _MainTex_ST.zw
				
				// transform from object-space to world-space via mul with Valiable of Unity Shader 
				// i.normal = mul(unity_ObjectToWorld, float4(v.normal, 0));
				// i.normal = normalize(i.normal); // after mul, value will scale -> we have to normalize them after the transformation

				// this code is hard vcl. Maybe when scale object -> normals will wrong -> mul matrix on the sky -> BOOM -> right normal -> magic shader
				i.normal = UnityObjectToWorldNormal(v.normal);

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
			float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
				i.normal = normalize(i.normal);

				// dot(float3(0, 1, 0), i.normal) is mul not dir of 2 vector
				// saturate to clamp value from 0 -> 1
				// DotClamped = saturate(dot(float3(0, 1, 0), i.normal)); 
				// return DotClamped(float3(0, 1, 0), i.normal);

				float3 lightDir = _WorldSpaceLightPos0.xyz; // maybe dir: from point -> light sourcer
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 lightColor = _LightColor0.rgb;

				// return DotClamped(lightDir, i.normal);
				// return float4(lightDir, 1);

				// The color of the diffuse reflectivity of a material is known as its albedo
				//  it describes how much of the red, green, and blue color channels are diffusely reflected
				float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

				// if Specular high -> reduce albedo
				// albedo *= 1 - _SpecularTint.rgb;
				// albedo *= 1 -
				// 	max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));

				// float oneMinusReflectivity;
				// albedo = EnergyConservationBetweenDiffuseAndSpecular(
				// 	albedo, _SpecularTint.rgb, oneMinusReflectivity
				// );

				// float3 specularTint = albedo * _Metallic;
				// float oneMinusReflectivity = 1 - _Metallic;
				// albedo *= oneMinusReflectivity;

				float3 specularTint; // = albedo * _Metallic;
				float oneMinusReflectivity; // = 1 - _Metallic;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);

				// float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);

				// float3 reflectionDir = reflect(-lightDir, i.normal); 
				// return float4(diffuse, 1);
				// return float4(reflectionDir * 0.5 + 0.5, 1);
				// return DotClamped(viewDir, reflectionDir);
				// return pow(
				// 	DotClamped(viewDir, reflectionDir),
				// 	_Smoothness * 100
				// );

				// // Blinn-Phong
				// float3 halfVector = normalize(lightDir + viewDir);
				// float3 specular = specularTint * lightColor * pow(
				// 	DotClamped(halfVector, i.normal),
				// 	_Smoothness * 100
				// );

				// return float4(specular, 1);
				// return float4(diffuse + specular, 1);
				// return float4(diffuse * specular, 1);

				// UnityLightingCommon defines a simple UnityLight structure which Unity shaders use to pass light data around
				UnityLight light;
				light.color = lightColor;
				light.dir = lightDir;
				light.ndotl = DotClamped(i.normal, lightDir);

				// The final argument is for the indirect light. We have to use the UnityIndirect structure for that, which is also defined in UnityLightingCommon. 
				// It contains two colors, a diffuse and a specular one. 
				// The diffuse color represents the ambient light, 
				// while the specular color represents environmental reflections.
				UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

				return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,
					light,  indirectLight

				);
			}

			ENDCG
		}
	}
}