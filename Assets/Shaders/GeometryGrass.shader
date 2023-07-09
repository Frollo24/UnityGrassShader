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

		[Header(Tesselation Factor)]
		_TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1

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

#if UNITY_VERSION >= 202120
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
#else
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#endif
			#pragma multi_compile _ _SHADOWS_SOFT

			#define UNITY_PI 3.14159265359f
			#define UNITY_TWO_PI 6.28318530718f

			#include "Source/GeometryGrassInput.hlsl"
			#include "Source/GeometryGrassHelperFunctions.hlsl"
			#include "Source/GeometryGrassExtraStages.hlsl"
		ENDHLSL

		Pass
		{
			Name "GrassPass"
			Tags { "LightMode" = "UniversalForward" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma require geometry
			#pragma require tessellation tessHW

			#pragma vertex VSMain
			#pragma hull HSMain
			#pragma domain DSMain
			#pragma geometry GSMain
			#pragma fragment PSMain

			#include "Source/GeometryGrassForwardPass.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma require geometry
			#pragma require tessellation tessHW

			#pragma vertex VSMain
			#pragma hull HSMain
			#pragma domain DSMain
			#pragma geometry GSMain
			#pragma fragment PSMain

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

			// TODO: Substitute with main shadow caster pass when possible
			#include "Source/GeometryGrassShadowCasterPass.hlsl"
			ENDHLSL
		}
	}
}
