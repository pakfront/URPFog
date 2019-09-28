#ifndef FOG_INCLUDED
#define FOG_INCLUDED


float IntegralFog(float scattering, float distance, float3 rayDir, float3 rayOrigin )
{
    #ifndef HEIGHT_FOG
    float fogAmount = 1.0 - exp( -distance * scattering );
    fogAmount *= _Presence;
    #else
    float b = _HeightFogDropoff;
    float c = scattering/b;
    float fogAmount = c * exp(-rayOrigin.y*b) * (1.0-exp( -distance*rayDir.y*b ))/rayDir.y;
    fogAmount *= _Presence;
    fogAmount = saturate(fogAmount);
    #endif
    return fogAmount;
}

float3 IntegralFog(float3 scattering, float distance, float3 rayDir, float3 rayOrigin )
{
    #ifndef HEIGHT_FOG
    return _Presence * float3( 
        1 - exp( -distance * scattering.r), 
        1 - exp( -distance * scattering.g),
        1 - exp( -distance * scattering.b)); 
    #else
    float b = _HeightFogDropoff;
    float3 fogAmount = float3(
        scattering.r/b * exp(-rayOrigin.y*b) * (1.0-exp( -distance*rayDir.y*b ))/rayDir.y,
        scattering.g/b * exp(-rayOrigin.y*b) * (1.0-exp( -distance*rayDir.y*b ))/rayDir.y,
        scattering.b/b * exp(-rayOrigin.y*b) * (1.0-exp( -distance*rayDir.y*b ))/rayDir.y);
    fogAmount *= _Presence;
    fogAmount = saturate(fogAmount);
    return fogAmount;
    #endif
}

float3 DistanceFog(float3 original, float distance )
{
    float fogAmount = 1.0 - exp( -distance * _Scattering );
    fogAmount *= _Presence;
    return lerp( original, _ScatteringTint, fogAmount );
}

float3 HeightFog(float3 original, float distance, float3 rayDir, float3 rayOrigin )
{
    return lerp(original, _ScatteringTint, IntegralFog(_Scattering, distance, rayDir, rayOrigin));
}

float3 ScatteringHeightFog(float3 original, float distance, float3 rayDir, float3 rayOrigin )
{
    Light mainLight = GetMainLight();
    float lightAmount = max( dot(normalize(mainLight.direction), -rayDir), 0);

    float3  fogColor  = lerp( _ScatteringTint, mainLight.color, _LightPower * pow(lightAmount, 8) );

    float3 extColor = IntegralFog( 
        _Extinction * (1-_ExtinctionTint),
        distance, rayDir, rayOrigin);
            
    float3 insColor = IntegralFog(
        _Scattering * fogColor,
        distance, rayDir, rayOrigin);
     
    return original*(1.0-extColor) + insColor;
}

float3 RayMarchedFog(float3 original, float distance, float3 rayDir, float3 rayOrigin )
{

    int stepCount = _SampleCount;
	float stepDistance = distance / stepCount;
    float3 step = rayDir * stepDistance;

    Light mainLight = GetMainLight();
    half shadowStrength = GetMainLightShadowStrength();
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    
    float3 currentPosition = rayOrigin+step;
    float3 extColor = 0;
    float3 insColor = 0;

    // angle can be precalculated for directional lights
    // spots, points would have to be updated for each step
    float lightAmount = max( dot(normalize(mainLight.direction), -rayDir), 0);
    float3  fogColor  = lerp( _ScatteringTint, mainLight.color, _LightPower * pow(lightAmount, 8) );

    [loop]
    for (int i = 0; i < stepCount; ++i)
    {
        float4 coords = TransformWorldToShadowCoord(currentPosition);
        // Screenspace shadowmap is only used for directional lights which use orthogonal projection.
        float  atten = SampleShadowmap(coords, TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowSamplingData, shadowStrength, false);

        extColor += IntegralFog( 
            _Extinction * (1-_ExtinctionTint),
            stepDistance, rayDir, currentPosition);

        insColor += IntegralFog(
            _Scattering * fogColor,
            stepDistance, rayDir, currentPosition);

        currentPosition += step;      
    }
    return original*(1.0-extColor) + insColor;
}

#endif
