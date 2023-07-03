#ifndef GEOMETRY_GRASS_SHADOWCASTER_INCLUDED
#define GEOMETRY_GRASS_SHADOWCASTER_INCLUDED

float3 _LightDirection;
float3 _LightPosition;

// Custom vertex shader to apply shadow bias.
VSOutput VSMain(VSInput v)
{
    VSOutput o;

    o.normal = TransformObjectToWorldNormal(v.normal);
    o.tangent = v.tangent;
    o.uv = TRANSFORM_TEX(v.uv, _GrassMap);

    float3 positionWS = TransformObjectToWorld(v.position);

	// Code required to account for shadow bias.
#if _CASTING_PUNCTUAL_LIGHT_SHADOW
	float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif
    o.position = float4(ApplyShadowBias(positionWS, o.normal, lightDirectionWS), 1.0f);

    return o;
}

float4 PSMain(GSOutput i) : SV_Target
{
    Alpha(SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    return 0;
}
#endif
