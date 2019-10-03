using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(fileName = "WorleyNoiseComputeTexture", menuName = "Compute Shader/WorleyNoiseComputeTexture", order = 1)]
public class WorleyNoiseComputeTexture : ComputeTexture
{
    [Header("Worley Noise Settings")]
    public float scale = 1;
    public float tex2Low = -0.2f;
    public float tex2High = 1;
    public override void SetParameters()
    {
        base.SetParameters();
        computeShader.SetFloat("Scale", scale);
        computeShader.SetFloat("Tex2Low", tex2Low);
        computeShader.SetFloat("Tex2High", tex2High);
    }

}