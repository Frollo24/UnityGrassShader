Shader "CustomGrass/ProceduralGrass"
{
    Properties
    {
        [Header(Albedo)] // Albedo color properties
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

#if UNITY_VERSION >= 202120
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
#else
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#endif
			#pragma multi_compile _ _SHADOWS_SOFT

			struct VSInput
			{
				uint vertexID : SV_VertexID;
				uint instanceID : SV_InstanceID;
			};

			struct VSOutput
			{
				float4 positionCS : SV_Position;
				float4 positionWS : TEXCOORD0;
				float2 uv : TEXCOORD1;
			};

			StructuredBuffer<float3> _Positions;
			StructuredBuffer<float3> _Normals;
			StructuredBuffer<float2> _UVs;
			StructuredBuffer<float4x4> _TransformMatrices;

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _TipColor;
				sampler2D _BladeTexture;
				float4 _BladeTexture_ST;

				float _Cutoff;
			CBUFFER_END
		ENDHLSL

		Pass
		{
			Name "GrassPass"
			Tags { "LightMode" = "UniversalForward" }

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			VSOutput vert(VSInput input)
			{
				VSOutput o;

				float4 positionOS = float4(_Positions[input.vertexID], 1.0f);
				float4x4 objectToWorld = _TransformMatrices[input.instanceID];

				o.positionWS = mul(objectToWorld, positionOS);
				o.positionCS = mul(UNITY_MATRIX_VP, o.positionWS);
				o.uv = _UVs[input.vertexID];

				return o;
			}

			float4 frag(VSOutput input) : SV_Target
			{
				float4 bladeTint = tex2D(_BladeTexture, input.uv);

#ifdef MAIN_LIGHT_CALCULATE_SHADOWS
				// Shadow receiving
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = input.positionWS;

				float4 shadowCoord = GetShadowCoord(vertexInput);
				half shadowAttenuation = saturate(MainLightRealtimeShadow(shadowCoord) + 0.25f);
				float4 shadowColor = lerp(0.0f, 1.0f, shadowAttenuation);
				bladeTint *= shadowColor;

				Light light = GetMainLight();
				bladeTint *= float4(max(light.color.xyz, 0.01), 1);
#endif

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
			#pragma fragment PSMain

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

			float3 _LightDirection;
			float3 _LightPosition;

			// Custom vertex shader to apply shadow bias.
			VSOutput VSMain(VSInput input)
			{
				VSOutput o;

				float4 positionOS = float4(_Positions[input.vertexID], 1.0f);
				float3 normalOS = _Normals[input.vertexID];
				float4x4 objectToWorld = _TransformMatrices[input.instanceID];

				float4 positionWS = mul(objectToWorld, positionOS);
				o.positionCS = mul(UNITY_MATRIX_VP, positionWS);
				o.uv = _UVs[input.vertexID];

				float3 normalWS = TransformObjectToWorldNormal(normalOS);

				// Code required to account for shadow bias.
#if _CASTING_PUNCTUAL_LIGHT_SHADOW
				float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
				float3 lightDirectionWS = _LightDirection;
#endif
				o.positionWS = float4(ApplyShadowBias(positionWS, normalWS, lightDirectionWS), 1.0f);

				return o;
			}

			float4 PSMain(VSOutput i) : SV_Target
			{
				Alpha(SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
				return 0;
			}
			ENDHLSL
		}
    }
    FallBack "Diffuse"
}
