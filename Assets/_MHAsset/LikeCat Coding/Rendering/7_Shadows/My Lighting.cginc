
//To add support for multiple lights to our shader, we'll have to add more passes to it. 
//These passes will end up containing nearly identical code. 
//To prevent code duplication, we're going to move our shader code to an include file.


// this action to Prevent 2 include_files define the same sub include_file -> prevent compli error
#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc" // it use to ensure Light_effect in face will smooth when obejct is out range of light_source
#include "UnityPBSLighting.cginc" // Unity's standard shaders use a PBS approach

// To actually use the property, we have to add a variable to the shader code. 
// Its name has to exactly match the property name, so it'll be _Tint.
float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST; // ST is Scale and Translation -> use to titling and offset
			
float _Metallic;
float _Smoothness;

struct Interpolators
{
    float4 position : SV_POSITION; // position of clip space
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;

	#if defined(SHADOWS_SCREEN)
		float4 shadowCoordinates : TEXCOORD5;
	#endif
	
    #if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD6;
    #endif
};

struct VertexData
{
    float4 position : POSITION; // position of object-space
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0; // uv coordition of vertex which is included in mesh
};

 // use to both reads from and writes to the interpolators, so that becomes an 'inout' parameter.
void ComputeVertexLightColor(inout Interpolators i)
{
    #if defined(VERTEXLIGHT_ON)
  //      float3 lightPos = float3(
		//    unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x
	 //       );
		//float3 lightVec = lightPos - i.worldPos;
		//float3 lightDir = normalize(lightVec);
		//float ndotl = DotClamped(i.normal, lightDir);
		//float attenuation = 1 / (1 + dot(lightVec, lightVec)  * unity_4LightAtten0.x);
		//i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;
    
        i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.worldPos, i.normal
		);
	#endif
}

Interpolators MyVertexProgram(VertexData v)
{
    Interpolators i;

    i.position = UnityObjectToClipPos(v.position);
    i.worldPos = mul(unity_ObjectToWorld, v.position);
	// i.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
    i.uv = TRANSFORM_TEX(v.uv, _MainTex); // TRANSFORM_TEX(v.uv, _MainTex) = v.uv * _MainTex_ST.xy + _MainTex_ST.zw
    i.normal = UnityObjectToWorldNormal(v.normal);

	#if defined(SHADOWS_SCREEN)
		i.shadowCoordinates = i.position;
	#endif

	
    ComputeVertexLightColor(i);
    
    return i;
}

UnityLight CreateLight(Interpolators i)
{
    UnityLight light;
    
    //light.dir = _WorldSpaceLightPos0.xyz; // light_dir if light_source is Direction Light
    //light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos); // if light_source is POINT Light
    
    #if defined(POINT) || defined(SPOT)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #else
        light.dir = _WorldSpaceLightPos0.xyz;
	#endif
    
    //light.color = _LightColor0.rgb;
    
    //float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
    //float attenuation = 1 / (1 + (dot(lightVec, lightVec)) );
    //light.color = _LightColor0.rgb * attenuation;

	// attacnuation : Mô phỏng độ suy giảm ánh sáng -> Trong thực tế, ánh sáng từ nguồn sáng sẽ yếu dần khi di chuyển xa hơn, hoặc khi góc giữa bề mặt và nguồn sáng không phù hợp.
    // use to compute attacnuation for light
    // UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);

	#if defined(SHADOWS_SCREEN)
		float attenuation = tex2D(_ShadowMapTexture, i.shadowCoordinates.xy);
	#else
		UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
	#endif
	
    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);
    return light;
}

UnityIndirect CreateIndirectLight(Interpolators i)
{
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

    #if defined(VERTEXLIGHT_ON)
		    indirectLight.diffuse = i.vertexLightColor;
    #endif
    return indirectLight;
}

float4 MyFragmentProgram(Interpolators i) : SV_TARGET
{
    i.normal = normalize(i.normal);

    //float3 lightDir = _WorldSpaceLightPos0.xyz; // maybe dir: from point -> light sourcer
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    
    //float3 lightColor = _LightColor0.rgb;
    float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

    float3 specularTint; // = albedo * _Metallic;
    float oneMinusReflectivity; // = 1 - _Metallic;
    albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);
					
	// UnityLightingCommon defines a simple UnityLight structure which Unity shaders use to pass light data around
    //UnityLight light;
    //light.color = lightColor;
    //light.dir = lightDir;
    //light.ndotl = DotClamped(i.normal, lightDir);

    //UnityIndirect indirectLight;
    //indirectLight.diffuse = 0;
    //indirectLight.specular = 0;

    //return float4(CreateIndirectLight(i).diffuse, 1);
    
    return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,
					CreateLight(i), CreateIndirectLight(i)

				);
}

#endif