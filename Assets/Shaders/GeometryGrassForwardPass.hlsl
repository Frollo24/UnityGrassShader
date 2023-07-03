#ifndef GEOMETRY_GRASS_FORWARD_INCLUDED
#define GEOMETRY_GRASS_FORWARD_INCLUDED

VSOutput VSMain(in VSInput input)
{
    VSOutput output;
	//output.position = TransformObjectToHClip(input.position.xyz);
    output.position = float4(TransformObjectToWorld(input.position.xyz), 1.0f);
	//output.position = input.position;
    output.normal = input.normal;
    output.tangent = input.tangent;
    output.uv = input.uv;
    return output;
}

float4 PSMain(in GSOutput input) : SV_Target
{
    float4 bladeTint = tex2D(_BladeTexture, input.uv);

#ifdef MAIN_LIGHT_CALCULATE_SHADOWS
	// Shadow receiving
	VertexPositionInputs vertexInput = (VertexPositionInputs)0;
	vertexInput.positionWS = input.worldPos;

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
