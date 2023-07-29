#ifndef GEOMETRY_GRASS_STAGES_INCLUDED
#define GEOMETRY_GRASS_STAGES_INCLUDED

#include "GeometryGrassHelperFunctions.hlsl"

HullOutput PatchMain(InputPatch<VertexOutput, 3> patch)
{
    HullOutput output;
    
    // Get vertex position
    float3 vertPos0 = patch[0].positionWS.xyz;
    float3 vertPos1 = patch[1].positionWS.xyz;
    float3 vertPos2 = patch[2].positionWS.xyz;

    // Get medium point between each vertex
    float3 edgePos0 = 0.5f * (vertPos1 + vertPos2);
    float3 edgePos1 = 0.5f * (vertPos0 + vertPos2);
    float3 edgePos2 = 0.5f * (vertPos0 + vertPos1);
    
    // Calculate tesselation factor based on distance
    float dist0 = distance(edgePos0, _WorldSpaceCameraPos);
    float dist1 = distance(edgePos1, _WorldSpaceCameraPos);
    float dist2 = distance(edgePos2, _WorldSpaceCameraPos);
    
    float fadeDist = _TessMaxDistance - _TessMinDistance;

    float edgeFactor0 = saturate(1.0f - (dist0 - _TessMinDistance) / fadeDist);
    float edgeFactor1 = saturate(1.0f - (dist1 - _TessMinDistance) / fadeDist);
    float edgeFactor2 = saturate(1.0f - (dist2 - _TessMinDistance) / fadeDist);
    
    output.edge[0] = max(pow(edgeFactor0, 2) * _TessellationFactor, 1);
    output.edge[1] = max(pow(edgeFactor1, 2) * _TessellationFactor, 1);
    output.edge[2] = max(pow(edgeFactor2, 2) * _TessellationFactor, 1);
    output.inside = (output.edge[0] + output.edge[1] + output.edge[2]) / 3.0f;
    return output;
}

[domain("tri")]
[outputcontrolpoints(3)]
[outputtopology("triangle_cw")]
[partitioning("integer")]
[patchconstantfunc("PatchMain")]
VertexOutput HSMain(InputPatch<VertexOutput, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}

[domain("tri")]
VertexOutput DSMain(HullOutput input, OutputPatch<VertexOutput, 3> patch, float3 barycentricCoords : SV_DomainLocation)
{
    VertexOutput output;

    #define INTERPOLATE(fieldname) output.fieldname = \
					patch[0].fieldname * barycentricCoords.x + \
					patch[1].fieldname * barycentricCoords.y + \
					patch[2].fieldname * barycentricCoords.z;

	INTERPOLATE(uv)
	INTERPOLATE(positionWS)
	INTERPOLATE(normalOS)
	INTERPOLATE(tangentOS)
    
	INTERPOLATE(positionCS)
	INTERPOLATE(normalWS)
	INTERPOLATE(tangentWS)

    return output;
}

#define BLADE_SEGMENTS 3
[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
void GSMain(triangle VertexOutput input[3], inout TriangleStream<GeometryOutput> triStream)
{
    float3 pos = input[0].positionWS;
    float3 norm = input[0].normalOS;
    float4 tang = input[0].tangentOS;
    float3 binorm = cross(norm, tang.xyz) * tang.w;

    float3x3 tangentToLocal = float3x3
	(
		tang.x, binorm.x, norm.x,
		tang.y, binorm.y, norm.y,
		tang.z, binorm.z, norm.z
	);

    float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
    float3x3 baseTransformMatrix = mul(tangentToLocal, facingRotationMatrix);
    float3x3 tipTransformMatrix = baseTransformMatrix;
    float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BladeBendRandomRotation * UNITY_PI * 0.5, float3(-1, 0, 0));

// TODO: enable WIND_ON value editing based on texture value  
// #if WIND_ON
    float2 windUV = pos.xz * _WindMap_ST.xy + _WindMap_ST.zw + normalize(_WindVelocity.xz) * _WindFrequency * _Time.y;
    float2 windSample = (tex2Dlod(_WindMap, float4(windUV, 0, 0)).xy * 2.0 - 1.0) * length(_WindVelocity);
    float3 wind = normalize(float3(windSample.xy, 0));

    float3x3 windRotationMatrix = AngleAxis3x3(UNITY_PI * windSample, wind);
    tipTransformMatrix = mul(tipTransformMatrix, bendRotationMatrix);
    tipTransformMatrix = mul(tipTransformMatrix, windRotationMatrix);

    float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
    float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
    float forward = rand(pos.yyz) * _BladeBendForward;

    for (int i = 0; i < BLADE_SEGMENTS; i++)
    {
        float t = float(i) / float(BLADE_SEGMENTS);
        float segmentWidth = width * (1 - t);
        float segmentHeight = height * t;
        float segmentForward = pow(t, _BladeBendCurve) * forward;

        float3x3 segmentTransformMatrix = i == 0 ? baseTransformMatrix : tipTransformMatrix;
        triStream.Append(GenerateGrassVertex(pos, float3(segmentWidth, segmentHeight, segmentForward), float2(0, t), segmentTransformMatrix));
        triStream.Append(GenerateGrassVertex(pos, float3(-segmentWidth, segmentHeight, segmentForward), float2(1, t), segmentTransformMatrix));
    }
    triStream.Append(GenerateGrassVertex(pos, float3(0, height, forward), float2(0.5, 1), tipTransformMatrix));
}

#endif
