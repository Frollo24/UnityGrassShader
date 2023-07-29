#ifndef GEOMETRY_GRASS_INPUT_INCLUDED
#define GEOMETRY_GRASS_INPUT_INCLUDED

CBUFFER_START(UnityPerMaterial)
    // Albedo color properties
    float4 _TipColor;
    float4 _BaseColor;
    sampler2D _BladeTexture;
    float4 _BladeTexture_ST;

    // Blade bend properties
    float _BladeBendRandomRotation;
    float _BladeBendForward;
    float _BladeBendCurve;

    // Blade size properties
    float _BladeWidth;
    float _BladeWidthRandom;
    float _BladeHeight;
    float _BladeHeightRandom;

    // Tessellation properties
    float _TessellationFactor;
    float _TessMinDistance;
    float _TessMaxDistance;

    // Tessellation properties
    sampler2D _WindMap;
    float4 _WindMap_ST;
    float2 _WindFrequency;
    float _WindStrength;

    // Grass visibility properties
    sampler2D _GrassMap;
    float4 _GrassMap_ST;

    float _Cutoff;
CBUFFER_END

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

struct VertexOutput
{
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 normalOS : TEXCOORD2;
    float4 tangentOS : TEXCOORD3;
    
    float4 positionCS : SV_POSITION;
    float3 normalWS : NORMAL;
    float3 tangentWS : TANGENT;
};

struct HullOutput
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct GeometryOutput
{
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    
    float4 positionCS : SV_POSITION;
};
#endif
