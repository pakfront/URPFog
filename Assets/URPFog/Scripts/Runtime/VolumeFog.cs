using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class VolumeFog : ScriptableRendererFeature
    {
        [System.Serializable]
        public class VolumeFogSettings
        {
            public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;
            
            public Material volumeFogMaterial = null;
            public int volumeFogMaterialPassIndex = -1;
            public Target destination = Target.Color;
            public string textureId = "_VolumeFogPassTexture";
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
    }
}

