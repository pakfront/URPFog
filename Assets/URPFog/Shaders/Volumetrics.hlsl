#ifndef VOLUMETRICS_INCLUDED
#define VOLUMETRICS_INCLUDED


CBUFFER_START(UnityPerMaterial)
float4 _FogColor = 1;
float _HeightFogFloor = 0;
float _HeightFogDropoff = 0.5f;
int _SampleCount = 8;
float _Scattering = 0.5f;
float _Extinction = 0.5f;
float _Range = 200.0f;
float _SkyBoxExtinction = 0.9f;
float _MieGFloat = .319;
float4 MieG = 1;
float _NoiseScale;
float3 _NoiseSpeed;
CBUFFER_END


float GetDensity(float3 wpos)
{
      float density = 1;
#ifdef NOISE
      float noise = tex3D(_NoiseTexture, frac(wpos * _NoiseData.x + float3(_Time.y * _NoiseVelocity.x, 0, _Time.y * _NoiseVelocity.y)));
      noise = saturate(noise - _NoiseData.z) * _NoiseData.y;
      density = saturate(noise);
#endif
#ifdef HEIGHT_FOG
      // this is inverted??
      density *= exp(-(wpos.y - _HeightFogFloor) * _HeightFogDropoff);
#endif
      return density;
}        

//-----------------------------------------------------------------------------------------
// MieScattering
//-----------------------------------------------------------------------------------------
float MieScattering(float cosAngle, float4 g)
{
      return g.w * (g.x / (pow(g.y - g.z * cosAngle, 1.5)));			
}

// float4 RayMarch(float2 screenPos, float3 rayStart, float3 rayDir, float rayLength)
// {
// #ifdef DITHER_4_4
//       float2 interleavedPos = (fmod(floor(screenPos.xy), 4.0));
//       float offset = tex2D(_DitherTexture, interleavedPos / 4.0 + float2(0.5 / 4.0, 0.5 / 4.0)).w;
// #else
//       float2 interleavedPos = (fmod(floor(screenPos.xy), 8.0));
//       float offset = tex2D(_DitherTexture, interleavedPos / 8.0 + float2(0.5 / 8.0, 0.5 / 8.0)).w;
// #endif

//       int stepCount = SAMPLE_COUNT;

//       float stepSize = rayLength / stepCount;
//       float3 step = rayDir * stepSize;

//       float3 currentPosition = rayStart + step * offset;

//       float4 vlight = 0;

//       float cosAngle;
// #if defined (DIRECTIONAL) || defined (DIRECTIONAL_COOKIE)
// float extinction = 0;
//       cosAngle = dot(_LightDir.xyz, -rayDir);
// #else
//       // we don't know about density between camera and light's volume, assume 0.5
//       float extinction = length(_WorldSpaceCameraPos - currentPosition) * _VolumetricLight.y * 0.5;
// #endif
//       [loop]
//       for (int i = 0; i < stepCount; ++i)
//       {
//             float atten = GetLightAttenuation(currentPosition);
//             float density = GetDensity(currentPosition);

//       float scattering = _VolumetricLight.x * stepSize * density;
//             extinction += _VolumetricLight.y * stepSize * density;// +scattering;

//             float4 light = atten * scattering * exp(-extinction);

// //#if PHASE_FUNCTOIN
// #if !defined (DIRECTIONAL) && !defined (DIRECTIONAL_COOKIE)
//             // phase functino for spot and point lights
//       float3 tolight = normalize(currentPosition - _LightPos.xyz);
//       cosAngle = dot(tolight, -rayDir);
//             light *= MieScattering(cosAngle, _MieG);
// #endif          
// //#endif
//             vlight += light;

//             currentPosition += step;				
//       }

// #if defined (DIRECTIONAL) || defined (DIRECTIONAL_COOKIE)
//       // apply phase function for dir light
//       vlight *= MieScattering(cosAngle, _MieG);
// #endif

//       // apply light's color
//       vlight *= _LightColor;

//       vlight = max(0, vlight);
// #if defined (DIRECTIONAL) || defined (DIRECTIONAL_COOKIE) // use "proper" out-scattering/absorption for dir light 
//       vlight.w = exp(-extinction);
// #else
// vlight.w = 0;
// #endif
//       return vlight;
// }

float4 RayMarch(float3 rayStart, float3 rayDir, float rayLength)
{
      int stepCount = _SampleCount;

	float stepSize = rayLength / stepCount;
      float3 step = rayDir * stepSize;
      Light mainLight = GetMainLight();


      float4 vlight = 0;

      half shadowStrength = GetMainLightShadowStrength();
      ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
      float3 currentPosition = rayStart+step;
      float extinction = length(_WorldSpaceCameraPos - currentPosition) * _Extinction * 0.5;
      float cosAngle = dot(normalize(mainLight.direction), -rayDir);

      [loop]
      for (int i = 0; i < stepCount; ++i)
      {
            float density = GetDensity(currentPosition);
            float scattering = _Scattering * stepSize * density;
            extinction += _Extinction * stepSize * density;// +scattering;


            float4 coords = TransformWorldToShadowCoord(currentPosition);
            // Screenspace shadowmap is only used for directional lights which use orthogonal projection.
            float  atten = SampleShadowmap(coords, TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowSamplingData, shadowStrength, false);

            float4 light = atten * scattering * exp(-extinction);

            vlight += light;
            currentPosition += step;      
      }

      //move out of fragment
      float4 meiG =  float4(
            1 - (_MieGFloat * _MieGFloat),
            1 + (_MieGFloat * _MieGFloat),
            2 * _MieGFloat,
            1.0f / (4.0f * 3.14159265359));

      // vlight *= MieScattering(cosAngle, meiG);

      vlight.rgb *= mainLight.color;
      vlight.rgb *= _FogColor;
      vlight = max(0, vlight);
      // vlight.xyz = cosAngle;
      // vlight.a = 1;

      return vlight;
}
//include            
#endif