#ifndef GEOMETRY_GRASS_FORWARD_INCLUDED
#define GEOMETRY_GRASS_FORWARD_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

VertexOutput VSMain(in Attributes input)
{
    VertexOutput output;
	
    VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS.xyz, input.tangentOS);
	
    output.positionCS = posInputs.positionCS;
    output.positionWS = posInputs.positionWS;
    output.normalWS = normInputs.normalWS;
    output.tangentWS = normInputs.tangentWS;
	
    output.uv = input.uv;
    output.normalOS = input.normalOS;
    output.tangentOS = input.tangentOS;
    return output;
}

float4 PSMain(in GeometryOutput input) : SV_Target
{
    float4 bladeTint = tex2D(_BladeTexture, input.uv);

#ifdef MAIN_LIGHT_CALCULATE_SHADOWS
	// Shadow receiving
    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
	half shadowAttenuation = saturate(MainLightRealtimeShadow(shadowCoord) + 0.25f);
	float4 shadowColor = lerp(0.0f, 1.0f, shadowAttenuation);
	bladeTint *= shadowColor;

	Light light = GetMainLight();
	bladeTint *= float4(max(light.color.xyz, 0.01), 1);
#endif

    return lerp(_BaseColor, _TipColor, input.uv.y) * bladeTint;
}
#endif
