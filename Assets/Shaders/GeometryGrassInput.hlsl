#ifndef GEOMETRY_GRASS_INPUT_INCLUDED
#define GEOMETRY_GRASS_INPUT_INCLUDED

CBUFFER_START(UnityPerMaterial)
    float4 _TipColor;
    float4 _BaseColor;
    sampler2D _BladeTexture;
    float4 _BaseTex_ST;

    float _BendRotationRandom;
    float _BladeWidth;
    float _BladeWidthRandom;
    float _BladeHeight;
    float _BladeHeightRandom;
    float _BladeForward;
    float _BladeCurve;

    float _TessellationUniform;

    sampler2D _WindMap;
    float4 _WindMap_ST;
    float2 _WindFrequency;
    float _WindStrength;

    sampler2D _GrassMap;
    float4 _GrassMap_ST;

    float _Cutoff;
CBUFFER_END

struct VSInput
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct VSOutput
{
    float4 position : SV_POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct HSOutput
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct GSOutput
{
    float4 position : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 worldPos : TEXCOORD1;
};
#endif
