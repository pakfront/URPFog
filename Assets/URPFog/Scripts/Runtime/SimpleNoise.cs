using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(fileName = "ComputeShaderTexture", menuName = "Compute Shader/SimpleNoise", order = 1)]
public class SimpleNoise : ComputeShaderTexture
{
    public float scale = 1;

    public override void SetParameters()
    {
        base.SetParameters();
        computeShader.SetFloat("Scale", scale);
    }

}