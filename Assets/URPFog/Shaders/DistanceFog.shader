Shader "VolumetricFog/DistanceFog"
{
	Properties 
	{
	    [HideInInspector]_MainTex ("Base (RGB)", 2D) = "white" {}
		[Toggle(DEBUG_OUTPUT)]_DEBUG ("Debug Output", Float) = 0
		[Toggle(FOG_ONLY_OUTPUT)]_FOG_ONLY ("Fog Only Output", Float) = 0
		_Presence ("Fog Presence", Range(0, 1)) = 1 
		_Scattering ("Scattering",  Range(0, 4)) = .5 
		_ScatteringTint ("ScatteringTint", Color) = (0.5,0.6,0.7)
		_Extinction ("Extinction",  Range(0, 4)) = .5 
		_ExtinctionTint ("ExtinctionTint", Color) = (0,0,0)
		[Toggle(USE_MAX_DISTANCE)]_USE_MAX_DISTANCE ("Use Max Distance", Float) = 0
		_MaxDistance ("Max Distance", Range(1, 10000)) = 10000.0
		[Toggle(HEIGHT_FOG)]_HEIGHT_FOG ("Height Fog", Float) = 0
		_HeightFogFloor ("Height Fog Floor", Range(0, 10)) = 0
		_HeightFogDropoff ("Height Fog Dropoff", Range(0, 10)) = 0.5
    }
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		// Cull Front
        // ZWrite On
        // ColorMask RGB
        Blend SrcAlpha OneMinusSrcAlpha
        // Blend Off
		Pass
		{
            HLSLPROGRAM
            #define SHADOWS_SCREEN 1
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #pragma shader_feature_local DEBUG_OUTPUT
            #pragma shader_feature_local FOG_ONLY_OUTPUT
            #pragma shader_feature_local USE_MAX_DISTANCE
            #pragma shader_feature_local HEIGHT_FOG

            CBUFFER_START(UnityPerMaterial)
            float _Presence = 1;
            float _Extinction = 0.5f;
            float3 _ExtinctionTint = 0;
            float _Scattering = 0.5f;
            float3 _ScatteringTint = 1;
            float _MaxDistance = 10000.0;
            float _HeightFogDropoff = 1;
            CBUFFER_END

            #include "Fog.hlsl"

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            
#ifndef FOG_ONLY_OUTPUT
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
#endif
            
        struct Attributes
        {
            float4 positionOS   : POSITION;
            float2 texcoord : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings
        {
            half4  positionCS   : SV_POSITION;
            half4  uv           : TEXCOORD0;
            UNITY_VERTEX_OUTPUT_STEREO
        };

        Varyings Vertex(Attributes input)
        {
            Varyings output;
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

            float4 projPos = output.positionCS * 0.5;
            projPos.xy = projPos.xy + projPos.w;

            output.uv.xy = UnityStereoTransformScreenSpaceTex(input.texcoord);
            output.uv.zw = projPos.xy;

            return output;
        }

        half4 Fragment(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float deviceDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv.xy).r;

#if UNITY_REVERSED_Z
            deviceDepth = 1 - deviceDepth;
#endif
            deviceDepth = 2 * deviceDepth - 1; //NOTE: Currently must massage depth before computing CS position.

            float3 vpos = ComputeViewSpacePosition(input.uv.zw, deviceDepth, unity_CameraInvProjection);
            float3 wpos = mul(unity_CameraToWorld, float4(vpos, 1)).xyz;
            // there is probably a faster way to get world space depth
            // perhaps should be from view plane, not eye
            // how can I tell if I hit the sky?
            float3 viewDir = wpos-_WorldSpaceCameraPos;
            float distance = length(viewDir);
            viewDir /= distance;
#ifdef USE_MAX_DISTANCE
            distance = min(_MaxDistance, distance);
#endif

#ifdef DEBUG_OUTPUT
            return half4(distance.xxx/100.0,1);
#else
#ifdef FOG_ONLY_OUTPUT
            float4 mainTex = float4(0,0,0,1);
#else
            float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy);
#endif
            // return half4(DistanceFog(mainTex.rgb),distance,  mainTex.a);
            // return half4(HeightFog(mainTex.rgb, distance, viewDir, _WorldSpaceCameraPos), mainTex.a);
            return half4(ScatteringHeightFog(mainTex.rgb, distance, viewDir, _WorldSpaceCameraPos), mainTex.a);
#endif
        }
            
			#pragma vertex Vertex
			#pragma fragment Fragment
			
			ENDHLSL
		}
	} 
	FallBack "Diffuse"
}
