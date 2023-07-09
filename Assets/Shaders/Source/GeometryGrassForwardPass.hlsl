#ifndef GEOMETRY_GRASS_FORWARD_INCLUDED
#define GEOMETRY_GRASS_FORWARD_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

VSOutput VSMain(in VSInput input)
{
    VSOutput output;
	
    VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS.xyz, input.tangentOS);
	
    output.positionCS = posInputs.positionCS;
    output.positionWS = posInputs.positionWS;
    output.normalWS = normInputs.normalWS;
    output.tangentWS = normInputs.tangentWS;
	
    output.uv = input.uv;
    output.normal = input.normalOS;
    output.tangent = input.tangentOS;
    return output;
}

float4 PSMain(in GSOutput input) : SV_Target
{
    float4 bladeTint = tex2D(_BladeTexture, input.uv);

#ifdef MAIN_LIGHT_CALCULATE_SHADOWS
	// Shadow receiving
	VertexPositionInputs vertexInput = (VertexPositionInputs)0;
	vertexInput.positionWS = input.positionWS;

	float4 shadowCoord = GetShadowCoord(vertexInput);
	half shadowAttenuation = saturate(MainLightRealtimeShadow(shadowCoord) + 0.25f);
	float4 shadowColor = lerp(0.0f, 1.0f, shadowAttenuation);
	bladeTint *= shadowColor;

	Light light = GetMainLight();
	bladeTint *= float4(max(light.color.xyz, 0.01), 1);
#endif

    return lerp(_BaseColor, _TipColor, input.uv.y) * bladeTint;
}
#endif
