using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(fileName = "ComputeTexture", menuName = "Compute Shader/ComputeShaderTexture", order = 1)]
public class ComputeTexture : ScriptableObject
{
    [Header("Compute Shader")]
    public ComputeShader computeShader;
    public string kernelName = "CSMain";
    public TextureDimension dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
    public int size = 32;
    public Vector3Int computeThreads = new Vector3Int(8, 8, 8);
    public RenderTexture renderTexture;
    public RenderTextureFormat renderTextureFormat = RenderTextureFormat.ARGB32;

    [Header("Texture Asset Output")]
    public ComputeShader texture3DSlicer;
    public string assetName;
    public TextureFormat assetTextureFormat = TextureFormat.ARGB32;
    // TODO support export as PNG as well


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

		// if (texture3DSlicer == null)
		// 	texture3DSlicer = (ComputeShader)Resources.Load("Texture3DSlicer");
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
	}

	public void Regenerate()
    {
		if (renderTexture == null) CreateRenderTexture();
        DispatchComputeShader();
    }

    public void Clear()
    {
        if (renderTexture != null)
        {
            renderTexture.DiscardContents();
            renderTexture = null;
        }
    }

    // RenderTexture Copy3DSliceToRenderTexture(int layer)
    // {
    //     RenderTexture result = new RenderTexture(size, size, 0, renderTextureFormat);
    //     result.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
    //     result.enableRandomWrite = true;
    //     result.wrapMode = TextureWrapMode.Clamp;
    //     result.Create();

    //     int kernelIndex = texture3DSlicer.FindKernel("CSMain");
    //     texture3DSlicer.SetTexture(kernelIndex, "noise", renderTexture);
    //     texture3DSlicer.SetInt("layer", layer);
    //     texture3DSlicer.SetTexture(kernelIndex, "Result", result);
    //     texture3DSlicer.Dispatch(kernelIndex, size, size, 1);

    //     return result;
    // }

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

#if UNITY_EDITOR
    public virtual void SaveAsset()
    {
        string path = "Assets/" + assetName + ".asset";
        switch (dimension)
        {
            case TextureDimension.Tex2D:
                Texture2D output2D = RenderTextureUtils.ConvertToTexture2D(renderTexture, 0,  size, assetTextureFormat);
				UnityEditor.AssetDatabase.CreateAsset(output2D, path);
				Debug.Log("Wrote 2D " + output2D + " to " + path, this);
                break;
            case TextureDimension.Tex3D:
                Texture3D output3D = RenderTextureUtils.ConvertToTexture3D(renderTexture, size, assetTextureFormat);
				UnityEditor.AssetDatabase.CreateAsset(output3D, path);
				Debug.Log("Wrote 3D " + output3D + " to " + path, this);

                break;
            default:
                Debug.LogError("Only Tex2D and Tex3D dimensions are supported");
                break;
        }
    }
#endif
}
