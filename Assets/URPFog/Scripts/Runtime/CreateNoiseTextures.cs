using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateNoiseTextures
{
    public ComputeShader computeShader;
    public Color color =  Color.red;
    public RenderTexture result;
    public int size = 512;

    int kernel;
    public CreateNoiseTextures(ComputeShader computeShader) {}

    public void Create()
    {
        kernel = computeShader.FindKernel("CSMain");
        result = new RenderTexture(size,size,24);
        result.enableRandomWrite = true;
        result.Create();

        computeShader.SetTexture(kernel, "Result", result);
    }

    // Update is called once per frame
    void Update()
    {
        computeShader.SetVector("color", color);
        computeShader.Dispatch(kernel, size/8, size/8, 1);         
    }
}
