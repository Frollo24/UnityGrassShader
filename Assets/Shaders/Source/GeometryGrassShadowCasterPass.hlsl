#ifndef GEOMETRY_GRASS_SHADOWCASTER_INCLUDED
#define GEOMETRY_GRASS_SHADOWCASTER_INCLUDED

float3 _LightDirection;
float3 _LightPosition;

// Custom vertex shader to apply shadow bias.
VertexOutput VSMain(Attributes v)
{
    VertexOutput o;
    
    VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
    VertexNormalInputs normInputs = GetVertexNormalInputs(v.normalOS.xyz, v.tangentOS);
    
	// Code required to account for shadow bias.
#if _CASTING_PUNCTUAL_LIGHT_SHADOW
	float3 lightDirectionWS = normalize(_LightPosition - posInputs.positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif
    o.positionWS = ApplyShadowBias(posInputs.positionWS, normInputs.normalWS, lightDirectionWS);
    o.positionCS = TransformWorldToHClip(o.positionWS);
    
    o.normalWS = normInputs.normalWS;
    o.tangentWS = normInputs.tangentWS;
    
    o.uv = TRANSFORM_TEX(v.uv, _BladeTexture);
    o.normalOS = v.normalOS;
    o.tangentOS = v.tangentOS;

    return o;
}

float4 PSMain(GeometryOutput i) : SV_Target
{
    Alpha(SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    return 0;
}
#endif
