Shader "CustomGrass/GeometryGrass"
{
	Properties
	{
		[Header(Albedo)] // Albedo color properties
		_TipColor("Tip Color", Color) = (0.5792569, 0.846, 0.3297231, 1)
		_BaseColor("Base Color", Color) = (0.06129726, 0.378, 0.07151345, 1)
		_BladeTexture("Blade Texture", 2D) = "white" {}

		[Header(Blade Bend)] // Blade bend rotation
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2

		[Header(Blade Size)] // Blade size properties
		_BladeWidth("Blade Width", Float) = 0.05
		_BladeWidthRandom("Blade Width Random", Float) = 0.02
		_BladeHeight("Blade Width", Float) = 0.5
		_BladeHeightRandom("Blade Width Random", Float) = 0.3
		_BladeForward("Blade Forward Amount", Float) = 0.38
		_BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2

		[Header(Wind Parameters)] // Wind properties.
		_WindMap("Wind Offset Map", 2D) = "bump" {}
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", Float) = 1.0

		[Header(Grass visibility)] // Grass visibility properties.
		_GrassMap("Grass Visibility Map", 2D) = "white" {}
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

				float _BendRotationRandom;
				float _BladeWidth;
				float _BladeWidthRandom;
				float _BladeHeight;
				float _BladeHeightRandom;
				float _BladeForward;
				float _BladeCurve;

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
				float3 worldPos : TEXCOORD1;
			};

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

			GSOutput VertexTransformWorldToClip(float3 pos, float2 uv)
			{
				GSOutput o;
				o.position = TransformObjectToHClip(pos);
				o.uv = uv;
				o.worldPos = pos;
				return o;
			}

			// WHF -> WidthHeightForward
			GSOutput GenerateGrassVertex(float3 vertexPos, float3 WHF, float2 uv, float3x3 transformMatrix)
			{
				float3 tangentPoint = WHF.xzy;
				float3 localPosition = vertexPos + mul(transformMatrix, tangentPoint);
				return VertexTransformWorldToClip(localPosition, uv);
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
		ENDHLSL

		Pass
		{
			Name "GrassPass"
			Tags { "LightMode" = "UniversalForward" }

			ZWrite On
			ZTest LEqual

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
				float4 bladeTint = tex2D(_BladeTexture, input.uv);

				// Shadow receiving
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = input.worldPos;

				float4 shadowCoord = GetShadowCoord(vertexInput);
				half shadowAttenuation = saturate(MainLightRealtimeShadow(shadowCoord) + 0.25f);
				float4 shadowColor = lerp(0.0f, 1.0f, shadowAttenuation);
				bladeTint *= shadowColor;

				return lerp(_BaseColor, _TipColor, input.uv.y) * bladeTint;
			}
			ENDHLSL
		}

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma geometry GSMain
			#pragma fragment PSMain

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

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
			ENDHLSL
		}
	}
}
