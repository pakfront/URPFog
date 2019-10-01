using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class VolumeFogFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class VolumeFogSettings
        {
            public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;
            
            public Material volumeFogMaterial = null;
            public int volumeFogMaterialPassIndex = -1;
            public Target destination = Target.Color;
            public string textureId = "_VolumeFogPassTexture";

            public ComputeShaderTexture computeShaderTexture;
        }
        
        public enum Target
        {
            Color,
            Texture
        }

        public VolumeFogSettings settings = new VolumeFogSettings();
        RenderTargetHandle m_RenderTextureHandle;

        VolumeFogPass volumeFogPass;

        public override void Create()
        {
            var passIndex = settings.volumeFogMaterial != null ? settings.volumeFogMaterial.passCount - 1 : 1;
            settings.volumeFogMaterialPassIndex = Mathf.Clamp(settings.volumeFogMaterialPassIndex, -1, passIndex);

            if (settings.computeShaderTexture != null)
            {
                settings.computeShaderTexture.Generate();
                RenderTexture volumetricNoiseTexture = settings.computeShaderTexture.renderTexture;
                settings.volumeFogMaterial.SetTexture("_VolumetricNoiseTexture", volumetricNoiseTexture);
            }
            volumeFogPass = new VolumeFogPass(settings.Event, settings.volumeFogMaterial, settings.volumeFogMaterialPassIndex, name);
            m_RenderTextureHandle.Init(settings.textureId);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var src = renderer.cameraColorTarget;
            var dest = (settings.destination == Target.Color) ? RenderTargetHandle.CameraTarget : m_RenderTextureHandle;

            if (settings.volumeFogMaterial == null)
            {
                Debug.LogWarningFormat("Missing VolumeFog Material. {0} volumeFog pass will not execute. Check for missing reference in the assigned renderer.", GetType().Name);
                return;
            }

            volumeFogPass.Setup(src, dest);
            renderer.EnqueuePass(volumeFogPass);
        }

        // public RenderTexture ExecuteComputeShader2D(ComputeShader computeShader)
        // {
        //     Debug.Log("Executing Compute Shader 2D"+computeShader);

        //     int size = 512;

        //     int kernel = computeShader.FindKernel("CSMain");
        //     RenderTexture result = new RenderTexture(size,size,24);
        //     result.enableRandomWrite = true;
        //     result.Create();

        //     computeShader.SetTexture(kernel, "Result", result);
        //     computeShader.SetVector("color", Color.red);
        //     computeShader.Dispatch(kernel, size/8, size/8, 1); 
        //     return result;
        // }


        // public RenderTexture ExecuteComputeShader3D(ComputeShader computeShader)
        // {
        //     Debug.Log("Executing Compute Shader 3D"+computeShader);

        //     int size = 32;

        //     int kernel = computeShader.FindKernel("CSMain");
        //     RenderTexture result = new RenderTexture(size,size,0);
        //     result.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        //     result.volumeDepth = size;
        //     result.format = RenderTextureFormat.R16; 
        //     result.enableRandomWrite = true;
        //     result.Create();

        //     computeShader.SetTexture(kernel, "Result", result);
        //     computeShader.SetVector("color", Color.red);
        //     computeShader.Dispatch(kernel, size/8, size/8, 1); 
        //     return result;
        // }
    }
}

