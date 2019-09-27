#ifndef FOG_INCLUDED
#define FOG_INCLUDED


float3 SimpleFog(float3 original, float distance )
{
    float fogAmount = 1.0 - exp( -distance * _Scattering );
    return lerp( original, _ScatteringTint, fogAmount );
}

float3 SimpleHeightFog(float3 original, float distance, float3 rayDir, float3 rayOrigin )
{
    #ifndef HEIGHT_FOG
    float fogAmount = 1.0 - exp( -distance * _Scattering );
    #else
    float b = _HeightFogDropoff;
    float c = _Scattering/b;
    float fogAmount = c * exp(-rayOrigin.y*b) * (1.0-exp( -distance*rayDir.y*b ))/rayDir.y;
    fogAmount = saturate(fogAmount);
    #endif
    return lerp(original, _ScatteringTint, fogAmount);
    // float fogAmount = c * exp(-rayOrigin.y*b) * (1.0-exp( -distance*rayDir.y*b ))/rayDir.y;
    // return lerp( original, _ScatteringTint, fogAmount );
}

float3 ScatteringFog(float3 original, float distance , float3 rayDir)
{
    float fogAmount = 1.0 - exp( -distance * _Scattering );
    Light mainLight = GetMainLight();
    float lightAmount = max( dot(normalize(mainLight.direction), -rayDir), 0);

    float3  fogColor  = lerp( _ScatteringTint, // bluish
                           mainLight.color, // yellowish
                           pow(lightAmount,8.0) );
    return lerp( original, fogColor, fogAmount );
}

float3 ExtinctionScatteringFog(float3 original, float distance, float3 rayDir )
{
    Light mainLight = GetMainLight();
    float lightAmount = max( dot(normalize(mainLight.direction), -rayDir), 0);

    float3  fogColor  = lerp( _ScatteringTint, // bluish
                           mainLight.color, // yellowish
                           pow(lightAmount,8.0) );


      float3 extColor = _Presence * float3( 
        1 - exp( -distance * (_Extinction * (1-_ExtinctionTint.x)) ), 
        1 - exp( -distance * (_Extinction * (1-_ExtinctionTint.y)) ),
        1 - exp( -distance * (_Extinction * (1-_ExtinctionTint.z)) ));
    float3 insColor = _Presence * float3( 
        1 - exp( -distance * (_Scattering * (fogColor.x))), 
        1 - exp( -distance * (_Scattering * (fogColor.y))),
        1 - exp( -distance * (_Scattering * (fogColor.z))));  
    return original*(1.0-extColor) + insColor;
}

#endif
