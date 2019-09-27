#ifndef FOG_INCLUDED
#define FOG_INCLUDED


float FogAmount(float scattering, float distance, float3 rayDir, float3 rayOrigin )
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

float3 FogAmount(float3 scattering, float distance, float3 rayDir, float3 rayOrigin )
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
    return lerp(original, _ScatteringTint, FogAmount(_Scattering, distance, rayDir, rayOrigin));
}

float3 ScatteringHeightFog(float3 original, float distance, float3 rayDir, float3 rayOrigin )
{
    Light mainLight = GetMainLight();
    float lightAmount = max( dot(normalize(mainLight.direction), -rayDir), 0);

    float3  fogColor  = lerp( _ScatteringTint, mainLight.color, pow(lightAmount,8.0) );

    float3 extColor = FogAmount( 
        _Extinction * (1-_ExtinctionTint),
        distance, rayDir, rayOrigin);
            
    float3 insColor = FogAmount(
        _Scattering * fogColor,
        distance, rayDir, rayOrigin);
     
    return original*(1.0-extColor) + insColor;
}

#endif
