#ifndef FOG_INCLUDED
#define FOG_INCLUDED

CBUFFER_START(UnityPerMaterial)
float _Presence = 1;
float _Extinction = 0.5f;
float3 _ExtinctionTint = 0;
float _Scattering = 0.5f;
float3 _ScatteringTint = 1;
CBUFFER_END

float3 ExtinctionFog(float distance, float3 original)
{
    float fogAmount = 1.0 - exp( -distance * _Extinction.x );
    return lerp( original, _ScatteringTint, fogAmount );
}

float3 ExtinctionScatteringFog(float distance, float3 original)
{
    // float fogAmount = 1.0 - exp( -distance * _Extinction.x );
    //return original*(1.0-fogAmount) + _FogColor*fogAmount;
    //return original*(1.0- (exp( -distance * _Extinction.x ))) + _FogColor*fogAmount;
    
    // return original*(1.0-exp(-distance*_Extinction.x)) + _FogColor*exp(-distance*_Extinction.x);
    // return original*(1.0-exp(-distance*_Extinction.x));// + _FogColor*exp(-distance*_Extinction.x);
    // return original * (1.0-exp(-distance*_Extinction.x));// + _FogColor*exp(-distance*_Extinction.x);

    // float3 extColor = float3( exp(-distance*_Extinction.x), exp(-distance*_Extinction.x) exp(-distance*_Extinction.x) );
    // float3 insColor = float3( exp(-distance*_Scattering.x), exp(-distance*_Scattering.x) exp(-distance*_Scattering.x) );
    // return original*(1.0-extColor) + fogColor*insColor;
      float3 extColor = _Presence * float3( 
        1 - exp( -distance * (_Extinction * (1-_ExtinctionTint.x)) ), 
        1 - exp( -distance * (_Extinction * (1-_ExtinctionTint.y)) ),
        1 - exp( -distance * (_Extinction * (1-_ExtinctionTint.z)) ));
    float3 insColor = _Presence * float3( 
        1 - exp( -distance * (_Scattering * (_ScatteringTint.x))), 
        1 - exp( -distance * (_Scattering * (_ScatteringTint.y))),
        1 - exp( -distance * (_Scattering * (_ScatteringTint.z))));  
    return original*(1.0-extColor) + insColor;
}

#endif
