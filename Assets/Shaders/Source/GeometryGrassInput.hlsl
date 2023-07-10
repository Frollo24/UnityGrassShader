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
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

struct VSOutput
{
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 normalOS : TEXCOORD2;
    float4 tangentOS : TEXCOORD3;
    
    float4 positionCS : SV_POSITION;
    float3 normalWS : NORMAL;
    float3 tangentWS : TANGENT;
};

struct HSOutput
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct GSOutput
{
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    
    float4 positionCS : SV_POSITION;
};
#endif
