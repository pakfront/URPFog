using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(fileName = "SimplexNoiseComputeTexture", menuName = "Compute Shader/SimplexNoiseComputeTexture", order = 1)]
public class SimplexNoiseComputeTexture : ComputeTexture
{
    [Header("Simplex Noise Settings")]
    public float scale = 1;

    public override void SetParameters()
    {
        base.SetParameters();
        computeShader.SetFloat("Scale", scale);
    }

}