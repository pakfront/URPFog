using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(fileName = "ComputeShaderTexture", menuName = "Compute Shader/ComputeShaderTexture", order = 1)]
public class ComputeShaderTexture : ScriptableObject
{
    [Header("Compute Shader")]
    public ComputeShader computeShader;
    public string kernelName = "CSMain";
    public TextureDimension dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
    public int size = 32;
    public Vector3Int computeThreads = new Vector3Int(8, 8, 8);
    public RenderTexture renderTexture;
    public RenderTextureFormat renderTextureFormat = RenderTextureFormat.ARGB32;

	public Texture2D output2D;
	public Texture3D output3D;

    [Header("Texture Asset Output")]
    public ComputeShader texture3DSlicer;
    public string assetName;
    public TextureFormat assetTextureFormat = TextureFormat.ARGB32;
    // TODO support export as PNG slices
    int kernel;

    void OnValidate()
    {
        switch (dimension)
        {
            case TextureDimension.Tex2D:
            case TextureDimension.Tex3D:
                break;
            default:
                Debug.LogError("Only Tex2D and Tex3D dimensions are supported");
                break;
        }

		if (texture3DSlicer == null)
			texture3DSlicer = (ComputeShader)Resources.Load("Texture3DSlicer");
    }

    public int VolumeDepth
    {
        get
        {
            // return dimension == UnityEngine.Rendering.TextureDimension.Tex3D ? size : 1;
            return dimension == UnityEngine.Rendering.TextureDimension.Tex3D ? size : 1;
        }
    }

    public virtual void SetParameters()
    {
        computeShader.SetFloat("Tex3DRes", size);
        computeShader.SetTexture(kernel, "Tex3D", renderTexture);
        // ... add any custom shader parameters in subclass
    }

    public void CreateRenderTexture()
    {
        //We use 0 bit depth buffer because Unity currently does not support depth buffers in 3D textures
        RenderTexture rt = new RenderTexture(size, size, 0, renderTextureFormat);
		rt.name = name+"RenderTex";
        rt.enableRandomWrite = true;
        rt.dimension = TextureDimension.Tex3D;
        rt.volumeDepth = VolumeDepth; // 1 if 2d
        rt.Create();
        renderTexture = rt;
    }
    public void DispatchComputeShader()
    {
        kernel = computeShader.FindKernel(kernelName);
        SetParameters();
        computeShader.Dispatch(kernel,
            size / computeThreads.x,
            size / computeThreads.y,
            dimension == UnityEngine.Rendering.TextureDimension.Tex3D ? size / computeThreads.z : 1
            );
    }

    public void Generate()
    {
		Clear();
        CreateRenderTexture();
        DispatchComputeShader();
		// UpdateOutputTextures();
	}

	public void Regenerate()
    {
        DispatchComputeShader();
		// UpdateOutputTextures();
    }

    public void Clear()
    {
        if (renderTexture != null)
        {
            renderTexture.DiscardContents();
            renderTexture = null;
        }
		output2D = null;
		output3D = null;
    }

    RenderTexture Copy3DSliceToRenderTexture(int layer)
    {
        RenderTexture result = new RenderTexture(size, size, 0, renderTextureFormat);
        result.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
        result.enableRandomWrite = true;
        result.wrapMode = TextureWrapMode.Clamp;
        result.Create();

        int kernelIndex = texture3DSlicer.FindKernel("CSMain");
        texture3DSlicer.SetTexture(kernelIndex, "noise", renderTexture);
        texture3DSlicer.SetInt("layer", layer);
        texture3DSlicer.SetTexture(kernelIndex, "Result", result);
        texture3DSlicer.Dispatch(kernelIndex, size, size, 1);

        return result;
    }

    //-------------------------------------------------------------------------------------------------------------------
    // Save/Utility Functions
    //-------------------------------------------------------------------------------------------------------------------
    protected Texture2D ConvertFromRenderTexture(RenderTexture rt, TextureFormat textureFormat)
    {
        Texture2D output = new Texture2D(size, size, textureFormat, true);
        RenderTexture.active = rt;
        output.ReadPixels(new Rect(0, 0, size, size), 0, 0);
        output.Apply();
        return output;
    }

	public void UpdateOutputTextures()
    {
        //for readability
        int dim = size;
        //Slice 3D Render Texture to individual layers
        RenderTexture[] layers = new RenderTexture[size];
        for (int i = 0; i < size; i++)
            layers[i] = Copy3DSliceToRenderTexture(i);
        //Write RenderTexture slices to static textures
        Texture2D[] finalSlices = new Texture2D[size];
		output2D = ConvertFromRenderTexture(layers[0], assetTextureFormat);
        for (int i = 0; i < size; i++)
		{
            finalSlices[i] = ConvertFromRenderTexture(layers[i], assetTextureFormat);
		}
        //Build 3D Texture from 2D slices
        output3D = new Texture3D(dim, dim, dim, assetTextureFormat, true);
        output3D.filterMode = FilterMode.Trilinear;
        Color[] outputPixels = output3D.GetPixels();
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

        output3D.SetPixels(outputPixels);
        output3D.Apply();
    }

#if UNITY_EDITOR
    public void SaveAsset3D(string path)
    {
        //for readability
        int dim = size;
        //Slice 3D Render Texture to individual layers
        RenderTexture[] layers = new RenderTexture[size];
        for (int i = 0; i < size; i++)
            layers[i] = Copy3DSliceToRenderTexture(i);
        //Write RenderTexture slices to static textures
        Texture2D[] finalSlices = new Texture2D[size];
        for (int i = 0; i < size; i++)
            finalSlices[i] = ConvertFromRenderTexture(layers[i], assetTextureFormat);
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

        UnityEditor.AssetDatabase.CreateAsset(output, path);
        Debug.Log("Wrote " + output + " to " + path, this);
    }

    public void SaveAsset2D(string path, int slice)
    {
        //for readability
        int dim = size;
        //Slice 3D Render Texture to individual layers
        RenderTexture layer = Copy3DSliceToRenderTexture(slice);
        //Write RenderTexture slices to static textures
        Texture2D finalSlice = ConvertFromRenderTexture(layer, assetTextureFormat);
        //Build 3D Texture from 2D slices
        Texture2D output = finalSlice;

        UnityEditor.AssetDatabase.CreateAsset(output, path);
        Debug.Log("Wrote  " + output + " to " + path, this);
    }


    public virtual void SaveAsset()
    {
        string path = "Assets/" + assetName + ".asset";
        switch (dimension)
        {
            case TextureDimension.Tex2D:
                SaveAsset2D(path, 0);
                break;
            case TextureDimension.Tex3D:
                SaveAsset3D(path);
                break;
            default:
                Debug.LogError("Only Tex2D and Tex3D dimensions are supported");
                break;
        }
    }
#endif
}
