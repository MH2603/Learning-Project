// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(MY_SHADOWS_INCLUDED)
#define MY_SHADOWS_INCLUDED

#include "UnityCG.cginc"

struct VertexData {
    float4 position : POSITION;
    float3 normal : NORMAL;
};

float4 MyShadowVertexProgram (VertexData v) : SV_POSITION {

    // return UnityObjectToClipPos(v.position);
    // float4 position = UnityObjectToClipPos(v.position);

    // To also support the normal bias, we have to move the vertex position based on the normal Vector -> So we have to add the normal to our vertex data
    float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
    
    // To support the depth bias, we can use the UnityApplyLinearShadowBias function, which is defined in UnityCG.
    return UnityApplyLinearShadowBias(position); 
    
}

half4 MyShadowFragmentProgram () : SV_TARGET {
    return 0;
}

#endif