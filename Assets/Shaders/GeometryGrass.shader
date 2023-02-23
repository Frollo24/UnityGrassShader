Shader "CustomGrass/GeometryGrass"
{
	Properties
	{
		// Albedo color properties
		_TipColor("Tip Color", Color) = (0.5792569, 0.846, 0.3297231, 1)
		_BaseColor("Base Color", Color) = (0.06129726, 0.378, 0.07151345, 1)
		_BladeTexture("Blade Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags 
		{
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
			"RenderPipeline" = "UniversalPipeline"
		}
		LOD 100
		Cull Off

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

			#define UNITY_PI 3.14159265359f
			#define UNITY_TWO_PI 6.28318530718f

			CBUFFER_START(UnityPerMaterial)
				float4 _TipColor;
				float4 _BaseColor;
				sampler2D _BladeTexture;
				float4 _BaseTex_ST;
			CBUFFER_END

			struct VSInput
			{
				float4 position : POSITION;
				float3 normal   : NORMAL;
				float4 tangent  : TANGENT;
				float2 uv       : TEXCOORD0;
			};

			struct VSOutput
			{
				 float4 position : SV_POSITION;
				 float3 normal   : NORMAL;
				 float4 tangent  : TANGENT;
				 float2 uv       : TEXCOORD0;
			};

			struct GSOutput
			{
				float4 position : SV_POSITION;
				float2 uv       : TEXCOORD0;
			};

			GSOutput VertexTransformWorldToClip(float3 pos, float2 uv)
			{
				GSOutput o;
				o.position = TransformObjectToHClip(pos);
				//o.position = pos;
				o.uv = uv;
				return o;
			}

			[maxvertexcount(3)]
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

				triStream.Append(VertexTransformWorldToClip(pos + mul(tangentToLocal, float3(0.5, 0, 0)), float2(0, 0)));
				triStream.Append(VertexTransformWorldToClip(pos + mul(tangentToLocal, float3(-0.5, 0, 0)), float2(1, 0)));
				triStream.Append(VertexTransformWorldToClip(pos + mul(tangentToLocal, float3(0, 0, 1)), float2(0.5, 1)));
			}
		ENDHLSL

		Pass
		{
			HLSLPROGRAM
			#pragma require geometry

			#pragma vertex VSMain
			#pragma geometry GSMain
			#pragma fragment PSMain

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
				return lerp(_BaseColor, _TipColor, input.uv.y);
			}
			ENDHLSL
		}
	}
}
