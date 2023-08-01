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
#define NEW_PATH 1
#if NEW_PATH
    InputData inputData = (InputData) 0;
    inputData.positionWS = input.positionWS;
    inputData.normalWS = NormalizeNormalPerPixel(input.normalWS);
    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    
    half shadowAttenuation = saturate(MainLightRealtimeShadow(inputData.shadowCoord) + 0.05f);
    Light mainLight = GetMainLight();
    inputData.bakedGI = max(mainLight.color.rgb, 0.01) * shadowAttenuation;
    
    SurfaceData surface = (SurfaceData) 0;
    surface.albedo = lerp(_BaseColor, _TipColor, input.uv.y);
    surface.alpha = 1;
    surface.metallic = 0;
    surface.specular = 0;
    surface.occlusion = 1;
    surface.normalTS = half3(0, 0, 1);
    
    return UniversalFragmentPBR(inputData, surface);
#else
    float4 bladeTint = tex2D(_BladeTexture, input.uv);

#ifdef MAIN_LIGHT_CALCULATE_SHADOWS
	// Shadow receiving
    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
	half shadowAttenuation = saturate(MainLightRealtimeShadow(shadowCoord) + 0.25f);
	float4 shadowColor = lerp(0.0f, 1.0f, shadowAttenuation);
	bladeTint *= shadowColor;

	Light light = GetMainLight();
	bladeTint *= float4(max(light.color.rgb + 0.75f, 0.01f), 1);
#endif

    return lerp(_BaseColor, _TipColor, input.uv.y) * bladeTint;
#endif
}
#endif
