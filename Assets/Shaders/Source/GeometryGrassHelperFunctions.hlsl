#ifndef GEOMETRY_GRASS_FUNCTIONS_INCLUDED
#define GEOMETRY_GRASS_FUNCTIONS_INCLUDED

// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
// Extended discussion on this function can be found at the following link:
// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
// Returns a number in the 0...1 range.
float rand(float3 co)
{
    return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

// Construct a rotation matrix that rotates around the provided axis, sourced from:
// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
float3x3 AngleAxis3x3(float angle, float3 axis)
{
    float c, s;
    sincos(angle, s, c);

    float t = 1 - c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;

    return float3x3
	(
		t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		t * x * z - s * y, t * y * z + s * x, t * z * z + c
	);
}

GeometryOutput VertexTransformWorldToClip(float3 pos, float3 norm, float2 uv)
{
    GeometryOutput o = (GeometryOutput)0;
    o.positionCS = TransformWorldToHClip(pos);
    
    o.uv = uv;
    o.positionWS = pos;
    o.normalWS = norm;
    return o;
}

// WHF -> WidthHeightForward
GeometryOutput GenerateGrassVertex(float3 vertexPos, float3 vertexNormal, float3 WHF, float2 uv, float3x3 transformMatrix)
{
    float3 tangentPoint = WHF.xzy;
    float3 worldPosition = vertexPos + mul(transformMatrix, tangentPoint);
    return VertexTransformWorldToClip(worldPosition, vertexNormal, uv);
}

// 
// Wind functions
//
float3 GenerateWindAxis(float3 grassPositionWS, out float2 windSample)
{
    float2 windUV = grassPositionWS.xz * _WindMap_ST.xy + _WindMap_ST.zw + normalize(-_WindVelocity.xz) * _WindFrequency * _Time.y;
    windSample = (tex2Dlod(_WindMap, float4(windUV, 0, 0)).xy * 2.0 - 1.0) * length(_WindVelocity);
    
    float3 windAxis = normalize(float3(windSample.xy, 0));
    return windAxis;
}

float3x3 GenerateWindRotationMatrix(float3 grassPositionWS)
{
    float2 windSample;
    float3 wind = GenerateWindAxis(grassPositionWS, windSample);
    float3x3 windRotationMatrix = AngleAxis3x3(UNITY_PI * windSample, wind);
    return windRotationMatrix;
}

#endif
