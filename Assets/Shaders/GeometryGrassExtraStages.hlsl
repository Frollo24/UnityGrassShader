#ifndef GEOMETRY_GRASS_STAGES_INCLUDED
#define GEOMETRY_GRASS_STAGES_INCLUDED

#include "GeometryGrassHelperFunctions.hlsl"

HSOutput PatchMain(InputPatch<VSOutput, 3> patch)
{
    HSOutput output;
    output.edge[0] = _TessellationUniform;
    output.edge[1] = _TessellationUniform;
    output.edge[2] = _TessellationUniform;
    output.inside = _TessellationUniform;
    return output;
}

[domain("tri")]
[outputcontrolpoints(3)]
[outputtopology("triangle_cw")]
[partitioning("integer")]
[patchconstantfunc("PatchMain")]
VSOutput HSMain(InputPatch<VSOutput, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}

[domain("tri")]
VSOutput DSMain(HSOutput input, OutputPatch<VSOutput, 3> patch, float3 barycentricCoords : SV_DomainLocation)
{
    VSOutput output;

    #define INTERPOLATE(fieldname) output.fieldname = \
					patch[0].fieldname * barycentricCoords.x + \
					patch[1].fieldname * barycentricCoords.y + \
					patch[2].fieldname * barycentricCoords.z;

	INTERPOLATE(position)
	INTERPOLATE(normal)
	INTERPOLATE(tangent)
	INTERPOLATE(uv)

    return output;
}

#define BLADE_SEGMENTS 3
[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
void GSMain(triangle VSOutput input[3], inout TriangleStream<GSOutput> triStream)
{
    float3 pos = input[0].position;
    float3 norm = input[0].normal;
    float4 tang = input[0].tangent;
    float3 binorm = cross(norm, tang) * tang.w;

    float3x3 tangentToLocal = float3x3
	(
		tang.x, binorm.x, norm.x,
		tang.y, binorm.y, norm.y,
		tang.z, binorm.z, norm.z
	);

    float2 windUV = pos.xz * _WindMap_ST.xy + _WindMap_ST.zw + _WindFrequency * _Time.y;
    float2 windSample = (tex2Dlod(_WindMap, float4(windUV, 0, 0)).xy * 2.0 - 1.0) * _WindStrength;
    float3 wind = normalize(float3(windSample.xy, 0));

    float3x3 windRotationMatrix = AngleAxis3x3(UNITY_PI * windSample, wind);
    float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
    float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));
    float3x3 transformMatrix = mul(tangentToLocal, windRotationMatrix);
    transformMatrix = mul(transformMatrix, facingRotationMatrix);
    transformMatrix = mul(transformMatrix, bendRotationMatrix);
    float3x3 transformFacingMatrix = mul(tangentToLocal, facingRotationMatrix);

    float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
    float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
    float forward = rand(pos.yyz) * _BladeForward;

    for (int i = 0; i < BLADE_SEGMENTS; i++)
    {
        float t = float(i) / float(BLADE_SEGMENTS);
        float segmentWidth = width * (1 - t);
        float segmentHeight = height * t;
        float segmentForward = pow(t, _BladeCurve) * forward;

        float3x3 segmentTransformMatrix = i == 0 ? transformFacingMatrix : transformMatrix;
        triStream.Append(GenerateGrassVertex(pos, float3(segmentWidth, segmentHeight, segmentForward), float2(0, t), segmentTransformMatrix));
        triStream.Append(GenerateGrassVertex(pos, float3(-segmentWidth, segmentHeight, segmentForward), float2(1, t), segmentTransformMatrix));
    }
    triStream.Append(GenerateGrassVertex(pos, float3(0, height, forward), float2(0.5, 1), transformMatrix));
}

#endif
