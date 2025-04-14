// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Custom/My Bumpiness Shader" {


	// Shader properties are declared in a separate block. Add it at the top of the shader.
	Properties {

		// The property name must be followed by a string and a type, in parenthesis, as if you're invoking a method. 
		// The string is used to label the property in the material inspector. In this case, the type is Color.
		_Tint("Tint", Color) = (1,1,1,1)

		_MainTex ("Albedo", 2D) = "white" {} // {} not function -> to ignore bug
		// [NoScaleOffset] _HeightMap ("Heights", 2D) = "gray" {}
		[NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1
		// _SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
		[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
		_DetailTex ("Detail Texture", 2D) = "gray" {}

		[NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1
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
			sampler2D _MainTex, _DetailTex;
			float4 _MainTex_ST,  _DetailTex_ST; // ST is Scale and Translation -> use to titling and offset
			sampler2D _HeightMap;
			sampler2D _NormalMap, _DetailNormalMap;
			float _BumpScale, _DetailBumpScale;

			// What is stored in _TexelSize variables?
			// Its first two components contain the texel sizes, as fractions of U and V. The other two components contain the amount of pixels. 
			// For example, in case of a 256×128 texture, it will contain (0.00390625, 0.0078125, 256, 128).
			float4 _HeightMap_TexelSize; // We can retrieve this information(The smallest sensible difference would cover a single texel) in the shader via a float4 variable with the _TexelSize suffix
			
			// float4 _SpecularTint;
			float _Metallic;
			float _Smoothness;

			struct Interpolators {
				float4 position : SV_POSITION; // position of clip space
				// float2 uv : TEXCOORD0;
				float4 uv : TEXCOORD0; // We can use float4 because The main UV go in XY, the detail UV go in ZW. 
				float3 normal : TEXCOORD1;
				float4 tangent : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				// float3 localPosition : TEXCOORD0;
			};

			struct VertexData {
				float4 position : POSITION; // position of object-space
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0; // uv coordition of vertex which is included in mesh
				float4 tangent : TANGENT;
			};


			// ver 03: use VertexData
			Interpolators MyVertexProgram (VertexData v) {
				Interpolators i;
				// i.localPosition = v.position.xyz;
				i.position = UnityObjectToClipPos(v.position);
				i.worldPos = mul(unity_ObjectToWorld, v.position);
				// i.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
				i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex); // TRANSFORM_TEX(v.uv, _MainTex) = v.uv * _MainTex_ST.xy + _MainTex_ST.zw
				i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);

				// this code is hard vcl. Maybe when scale object -> normals will wrong -> mul matrix on the sky -> BOOM -> right normal -> magic shader
				i.normal = UnityObjectToWorldNormal(v.normal);

				i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

				return i;
			}

			void InitializeFragmentNormal(inout Interpolators i) {
				// Because we're currently working with a quad that lies in the XZ plane, its normal vector is always (0, 1, 0). 
				// i.normal = float3(0, 1, 0);

				// A naive approach is to use the height as the normal's Y component
				// float h = tex2D(_HeightMap, i.uv);
				// i.normal = float3(0, h, 0);
				
				//#region Only use U dimensional for compute normal vector

				// Ver 01
				// float2 delta = float2( _HeightMap_TexelSize.x, 0);
				// float  h1    = tex2D(  _HeightMap, i.uv);
				// float  h2    = tex2D(  _HeightMap, i.uv + delta );

				// ver 02
				// float2 delta = float2( _HeightMap_TexelSize.x * 0.5, 0);
				// float  h1    = tex2D(  _HeightMap, i.uv - delta);
				// float  h2    = tex2D(  _HeightMap, i.uv + delta );

				// // Case 01:
				// // because every vectors range is one unit so now texture look like pronouned result and which produces very steep slopes
				// // i.normal     = float3(1, (h2 -h1)/delta.x, 0 ); 
				
				// // Case 02:
				// // we can change it to look better by mul with delta
				// // This is starting to look good, but the lighting is wrong. It is far too dark. 
				// // That's because we're directly using the tangent as a normal
				// // i.normal	 = float3(1, h2 -h1, 0); 

				// // case 03:
				// // To turn it into an upward-pointing normal vector, we have to rotate the tangent 90° around the Z axis.
				// i.normal = float3( h1 - h2, 1, 0 );

				// //#endregion

				// // #regin Compute U and V tangents after that, cross them to create complete normal vector

				// float2 du = float2(_HeightMap_TexelSize.x * 0.5, 0);
				// float u1 = tex2D(_HeightMap, i.uv - du);
				// float u2 = tex2D(_HeightMap, i.uv + du);
				// // float3 tu = float3(1, u2 - u1, 0);

				// float2 dv = float2(0, _HeightMap_TexelSize.y * 0.5);
				// float v1 = tex2D(_HeightMap, i.uv - dv);
				// float v2 = tex2D(_HeightMap, i.uv + dv);
				// // float3 tv = float3(0, v2 - v1, 1);

				// // use cross funtion to find normal vector when knew 2 tangent vectors
				// // i.normal = cross(tv, tu);

				// // after compute normal vector by cross funtion, we will see normal vector is [-f`u, 1 , -f`v]
				// // so we can ignore cross funtion
				// i.normal = float3(u1 - u2, 1, v1 - v2);

				// // #endregion

				// Ver 01
				// i.normal = tex2D(_NormalMap, i.uv).xyz * 2 - 1; //  we have to convert the normals back to their original −1–1 range, by computing 2N - 1
				// i.normal = i.normal.xzy; //  make sure to swap Y and Z

				// Ver 02
				// the texture preview shows RGB encoding but Unity actually uses DXT5nm. So we need to change it
				// DXT5nm only stores the X and Y components. ( With catlikecoding.com ) Y in (G/Y) channel and X in (A/W) channel. So (R/X) and (B/z) channel are not use
				// with chat gpt, X component is stored in the red (R/X) channel and Y component is stored in the alpha (A/W) channel.
				// i.normal.xy = tex2D(_NormalMap, i.uv).wy * 2 - 1;
				// i.normal.xy *= _BumpScale;
				// // i.normal.z = sqrt(1 - dot(i.normal.xy, i.normal.xy)); // because normal is unit vector so we can compute z component
				// i.normal.z = sqrt(1 - saturate(dot(i.normal.xy, i.normal.xy)));
				// i.normal = i.normal.xzy;

				//ver 2
				// i.normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
				// i.normal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
				// i.normal = i.normal.xzy;

				// ver 3: combine normal map and normal detail map
				float3 mainNormal =
					UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
				float3 detailNormal =
					UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);

				float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);
				// tangentSpaceNormal = tangentSpaceNormal.xzy;

				// float3 binormal = cross(i.normal, i.tangent.xyz) * i.tangent.w;
				float3 binormal = cross(i.normal, i.tangent.xyz) * (i.tangent.w * unity_WorldTransformParams.w);
		

				i.normal = normalize(
					tangentSpaceNormal.x * i.tangent +
					tangentSpaceNormal.y * binormal +
					tangentSpaceNormal.z * i.normal
				);

				// i.normal = (mainNormal + detailNormal) * 0.5;
				// i.normal =
				// 		float3(mainNormal.xy / mainNormal.z + detailNormal.xy / detailNormal.z, 1); // doc is very long so I has not read
				// i.normal =
				// 	float3(mainNormal.xy + detailNormal.xy, mainNormal.z * detailNormal.z);
				// i.normal = BlendNormals(mainNormal, detailNormal);

				// i.normal = i.normal.xzy;

				i.normal = normalize(i.normal);
			}


			// Ver 03
			float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
				InitializeFragmentNormal(i);


				float3 lightDir = _WorldSpaceLightPos0.xyz; // maybe dir: from point -> light sourcer
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 lightColor = _LightColor0.rgb;


				// The color of the diffuse reflectivity of a material is known as its albedo
				//  it describes how much of the red, green, and blue color channels are diffusely reflected
				float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
				// albedo *= tex2D(_HeightMap, i.uv);
				albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;

				float3 specularTint; // = albedo * _Metallic;
				float oneMinusReflectivity; // = 1 - _Metallic;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);

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