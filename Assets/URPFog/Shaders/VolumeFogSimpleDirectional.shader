Shader "VolumetricFog/SimpleDirectional"
{
	Properties 
	{
	    [HideInInspector]_MainTex ("Base (RGB)", 2D) = "white" {}
		[Toggle(DEBUG_OUTPUT)]_DEBUG ("Debug Output", Float) = 0
		[Toggle(FOG_ONLY_OUTPUT)]_FOG_ONLY ("Fog Only Output", Float) = 0
        [IntRange] _SampleCount ("Sample Count", Range (1, 48)) = 8
		_FogDensity ("Fog Density", Range(0, 4)) = 1 
		_FogColor ("Fog Color", Color) = (.3,.3,.3,1)
		_Scattering ("Scattering", Range(0, 10)) = 0.227
		_Extinction ("Extinction", Range(0, 10)) = 0.1
		_Range ("Range", Range(1, 50)) = 0.5
		_SkyBoxExtinction ("Sky Box Extinction", Range(0, 1)) = 0.9 
        _MeiGFloat ("MeiG", Range(0,1)) = 0.319
		[Toggle(NOISE)]_NOISE ("Noise", Float) = 0
        _VolumetricNoiseTexture("Volumetric Noise Texture",3D) = "" {} 
		_NoiseScale ("Noise Scale", Range(0, 10)) = 1
		_NoiseSpeed ("Noise Speed", Vector) = (1,0,1)
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

		Pass
		{
            HLSLPROGRAM
            #define SHADOWS_SCREEN 1
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #pragma shader_feature DEBUG_OUTPUT
            #pragma shader_feature FOG_ONLY_OUTPUT
            #pragma shader_feature HEIGHT_FOG
            #pragma shader_feature NOISE
            
            #include "Volumetrics.hlsl"

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

            float3 rayStart = _WorldSpaceCameraPos;
            float3 rayEnd = wpos;

            float3 rayDir = (rayEnd - rayStart);
            float rayLength = length(rayDir);
            rayDir /= rayLength;
            float4 fog = RayMarch(rayStart,rayDir,rayLength);
            //Fetch shadow coordinates for cascade.
            // float4 coords = TransformWorldToShadowCoord(wpos);
            // // Screenspace shadowmap is only used for directional lights which use orthogonal projection.
            // ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
            // half shadowStrength = GetMainLightShadowStrength();
            // float shadow = SampleShadowmap(coords, TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowSamplingData, shadowStrength, false);

            // float density = 0;//GetDensity(wpos);

#ifdef DEBUG_OUTPUT
            // return half4(density.xxx,1);
            // return half4(wpos.xyz, 1);
            // return half4(deviceDepth.xxx, 1);

            // return half4( _VolumetricNoiseTexture.Sample(sampler_VolumetricNoiseTexture, wpos.xyz/10.0f).xxx, 1 );
            float3 noiseUV = frac(wpos * _NoiseScale + _Time.y * _NoiseSpeed);
            //return half4( noiseUV, 1);
            // float noise = snoise(noiseUV);
            // float noise = _VolumetricNoiseTexture.Sample(sampler_VolumetricNoiseTexture, noiseUV);
            float3 noise = _VolumetricNoiseTexture.Sample(sampler_VolumetricNoiseTexture, noiseUV).xyz;
            return half4(noise.xxx, 1);
            // return half4(_VolumetricNoiseTexture.Sample(sampler_VolumetricNoiseTexture, noiseUV).xyz, 1);
           
            // return half4( _VolumetricNoiseTexture.Sample(sampler_VolumetricNoiseTexture, wpos.xyz/10.0f) );

            // return half4(shadow.xxx,1);
#else
#ifdef FOG_ONLY_OUTPUT
            return half4(fog);
#else
            return half4(fog+SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv));
#endif
#endif

        }
            
			#pragma vertex Vertex
			#pragma fragment Fragment
			
			ENDHLSL
		}
	} 
	FallBack "Diffuse"
}
