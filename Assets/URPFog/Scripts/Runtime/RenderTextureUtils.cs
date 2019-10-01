// MIT License

// Copyright (c) 2018 Michael Woodard

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

using UnityEngine;
using UnityEngine.Rendering;
public static class RenderTextureUtils
{
    public static Texture2D ConvertFromRenderTexture(RenderTexture input, int size, TextureFormat textureFormat)
    {
        Texture2D output = new Texture2D(size, size, textureFormat, true);
        RenderTexture.active = input;
        output.ReadPixels(new Rect(0, 0, size, size), 0, 0);
        output.Apply();
        return output;
    }

    public static RenderTexture Copy3DSliceToRenderTexture(RenderTexture input, int layer, int size, RenderTextureFormat renderTextureFormat)
    {

	    ComputeShader texture3DSlicer = (ComputeShader)Resources.Load("Texture3DSlicer");
        if (texture3DSlicer == null) 
        {
            Debug.LogError("Unable to Find Compute Shader Texture3DSlicer ");
            return null;
        }

        RenderTexture result = new RenderTexture(size, size, 0, renderTextureFormat);
        result.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
        result.enableRandomWrite = true;
        result.wrapMode = TextureWrapMode.Clamp;
        result.Create();

        int kernelIndex = texture3DSlicer.FindKernel("CSMain");
        texture3DSlicer.SetTexture(kernelIndex, "noise", input);
        texture3DSlicer.SetInt("layer", layer);
        texture3DSlicer.SetTexture(kernelIndex, "Result", result);
        texture3DSlicer.Dispatch(kernelIndex, size, size, 1);

        return result;
    }

    public static Texture3D ConvertToTexture3D(RenderTexture input, int size, TextureFormat assetTextureFormat)
    {
        //for readability
        int dim = size;
        //Slice 3D Render Texture to individual layers
        RenderTexture[] layers = new RenderTexture[size];
        for (int i = 0; i < size; i++)
            layers[i] = Copy3DSliceToRenderTexture(input, i, size, input.format);
        //Write RenderTexture slices to static textures
        Texture2D[] finalSlices = new Texture2D[size];
        for (int i = 0; i < size; i++)
            finalSlices[i] = ConvertFromRenderTexture(layers[i], size, assetTextureFormat);
        //Build 3D Texture from 2D slices
        Texture3D output = new Texture3D(dim, dim, dim, assetTextureFormat, true);
        output.filterMode = FilterMode.Trilinear;
        Color[] outputPixels = output.GetPixels();
        for (int k = 0; k < dim; k++)
        {
            Color[] layerPixels = finalSlices[k].GetPixels();
            for (int i = 0; i < dim; i++)
            {
                for (int j = 0; j < dim; j++)
                {
                    outputPixels[i + j * dim + k * dim * dim] = layerPixels[i + j * dim];
                }
            }
        }

        output.SetPixels(outputPixels);
        output.Apply();
        return output;
 
    }

    public static Texture2D ConvertToTexture2D(RenderTexture input, int slice, int size, TextureFormat assetTextureFormat)
   
    {
        //for readability
        int dim = size;
        //Slice 3D Render Texture to individual layers
        RenderTexture layer = RenderTextureUtils.Copy3DSliceToRenderTexture(input, slice, size, input.format);
        //Write RenderTexture slices to static textures
        Texture2D output = ConvertFromRenderTexture(layer, size, assetTextureFormat);
        return output;
    }   
}