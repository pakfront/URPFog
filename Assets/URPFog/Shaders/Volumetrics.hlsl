#ifndef VOLUMETRICS_INCLUDED
#define VOLUMETRICS_INCLUDED


CBUFFER_START(UnityPerMaterial)
float _FogDensity = 1;
float4 _FogColor = 1;
float _HeightFogFloor = 0;
float _HeightFogDropoff = 0.5f;
int _SampleCount = 8;
float _Scattering = 0.5f;
float _Extinction = 0.5f;
float _Range = 200.0f;
float _SkyBoxExtinction = 0.9f;
float _MieGFloat = .319;
// float4 MieG = 1;
float _NoiseScale;
float3 _NoiseSpeed;
CBUFFER_END

#ifdef NOISE
TEXTURE3D(_VolumetricNoiseTexture);
SAMPLER(sampler_VolumetricNoiseTexture);
#endif

float GetDensity(float3 wpos)
{
      float density = _FogDensity;
#ifdef NOISE
      float3 noiseUV = frac(wpos * 1.0/_NoiseScale + _Time.y * _NoiseSpeed);
      density *= _VolumetricNoiseTexture.Sample(sampler_VolumetricNoiseTexture, noiseUV).x;
#endif
#ifdef HEIGHT_FOG
      // this is inverted??
      density *= exp(-(wpos.y - _HeightFogFloor) * _HeightFogDropoff);
#endif
      return density;
}        

float4 RayMarch(float3 rayStart, float3 rayDir, float rayLength)
{
      int stepCount = _SampleCount;

	float stepSize = rayLength / stepCount;
      float3 step = rayDir * stepSize;
      Light mainLight = GetMainLight();


      half shadowStrength = GetMainLightShadowStrength();
      ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
      float3 currentPosition = rayStart+step;
      float extinction = length(_WorldSpaceCameraPos - currentPosition) * _Extinction * 0.5;

      // cosAngle can be precalculated for directional lights
      // spots, points would have to be updated for each step
      float cosAngle = dot(normalize(mainLight.direction), -rayDir);

      float accumulatedDensity = 0;

      [loop]
      for (int i = 0; i < stepCount; ++i)
      {
            float density = GetDensity(currentPosition);
            float scattering = _Scattering * stepSize * density;
            extinction += _Extinction * stepSize * density;// +scattering;


            float4 coords = TransformWorldToShadowCoord(currentPosition);
            // Screenspace shadowmap is only used for directional lights which use orthogonal projection.
            float  atten = SampleShadowmap(coords, TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowSamplingData, shadowStrength, false);

            accumulatedDensity += atten * scattering * exp(-extinction);
            currentPosition += step;      
      }

      // return float4(accumulatedDensity.xxx,1);

      //TODO move out of fragment
      float4 meiG =  float4(
            1 - (_MieGFloat * _MieGFloat),
            1 + (_MieGFloat * _MieGFloat),
            2 * _MieGFloat,
            1.0f / (4.0f * 3.14159265359));

      accumulatedDensity *=  meiG.w * (meiG.x / (pow(meiG.y - meiG.z * cosAngle, 1.5)));

      return max(0,float4(accumulatedDensity * mainLight.color.rgb * _FogColor.rgb,  accumulatedDensity));

      // accumulatedDensity.rgb *= mainLight.color;
      // accumulatedDensity.rgb *= _FogColor.rgb;
      // accumulatedDensity = max(0, vlight);

      // return vlight;
}
//include            
#endif