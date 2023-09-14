using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.XR;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class MobileBloom : MonoBehaviour
{
    [Range(0, 2)]
    public float BloomDiffusion = 2f;

    public Color BloomColor = Color.white;

    [Range(0, 5)]
    public float BloomAmount = 1f;

    [Range(0, 1)]
    public float BloomThreshold = 0f;

    [Range(0, 1)]
    public float BloomSoftness = 0f;

    private static readonly int blurAmountString = Shader.PropertyToID("_BlurAmount");
    private static readonly int bloomColorString = Shader.PropertyToID("_BloomColor");
    private static readonly int blDataString = Shader.PropertyToID("_BloomData");
    private static readonly int bloomTexString = Shader.PropertyToID("_BloomTex");

    public Material material = null;
    private int numberOfPasses;
    private float knee;
    private RenderTextureDescriptor half, quarter, eighths, sixths;
    private CommandBuffer commandBuffer;

    private void Awake()
    {
        commandBuffer = new CommandBuffer();
    }

    private void Update()
    {
        if (BloomDiffusion == 0 && BloomAmount == 0)
        {
            return;
        }

        // Materialが別ABに格納されるとリソースをうまくロードできない時がある
        // Updateで例外がでるとUCDのログに大量に出てしまうのでとりあえず何もしないようにしておく
        if (material == null)
        {
            return;
        }

        var camera = GetComponent<Camera>();

        camera.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, commandBuffer);
        commandBuffer.Clear();


        if (XRSettings.enabled)
        {
            half = XRSettings.eyeTextureDesc;
            half.height /= 2;
            half.width /= 2;
            quarter = XRSettings.eyeTextureDesc;
            quarter.height /= 4;
            quarter.width /= 4;
            eighths = XRSettings.eyeTextureDesc;
            eighths.height /= 8;
            eighths.width /= 8;
            sixths = XRSettings.eyeTextureDesc;
            sixths.height /= XRSettings.stereoRenderingMode == XRSettings.StereoRenderingMode.SinglePass ? 8 : 16;
            sixths.width /= XRSettings.stereoRenderingMode == XRSettings.StereoRenderingMode.SinglePass ? 8 : 16;
        }
        else
        {
            half = new RenderTextureDescriptor(Screen.width / 2, Screen.height / 2);
            quarter = new RenderTextureDescriptor(Screen.width / 4, Screen.height / 4);
            eighths = new RenderTextureDescriptor(Screen.width / 8, Screen.height / 8);
            sixths = new RenderTextureDescriptor(Screen.width / 16, Screen.height / 16);
        }

        material.SetFloat(blurAmountString, BloomDiffusion);
        material.SetColor(bloomColorString, BloomAmount * BloomColor);
        knee = BloomThreshold * BloomSoftness;
        material.SetVector(blDataString,
            new Vector4(BloomThreshold, BloomThreshold - knee, 2f * knee, 1f / (4f * knee + 0.00001f)));
        numberOfPasses = Mathf.Clamp(Mathf.CeilToInt(BloomDiffusion * 4), 1, 4);
        material.SetFloat(blurAmountString,
            numberOfPasses > 1
                ? BloomDiffusion > 1
                    ? BloomDiffusion
                    : (BloomDiffusion * 4 - Mathf.FloorToInt(BloomDiffusion * 4 - 0.001f)) * 0.5f + 0.5f
                : BloomDiffusion * 4);

        var blurTex = Shader.PropertyToID("blurTex");

        int source = Shader.PropertyToID("source");
        commandBuffer.GetTemporaryRT(source, -1, -1);
        commandBuffer.Blit(BuiltinRenderTextureType.CameraTarget, source);
        commandBuffer.Blit(source, BuiltinRenderTextureType.CameraTarget, material, 3);

        if (numberOfPasses == 1 || BloomDiffusion == 0)
        {
            commandBuffer.GetTemporaryRT(blurTex, half.width, half.height, 0, FilterMode.Bilinear);
            commandBuffer.Blit(BuiltinRenderTextureType.CameraTarget, blurTex, material, 0);
        }
        else if (numberOfPasses == 2)
        {
            commandBuffer.GetTemporaryRT(blurTex, half.width, half.height, 0, FilterMode.Bilinear);
            int temp1 = Shader.PropertyToID("temp1");
            commandBuffer.GetTemporaryRT(temp1, quarter.width, quarter.height, 0, FilterMode.Bilinear);
            commandBuffer.Blit(BuiltinRenderTextureType.CameraTarget, temp1, material, 0);
            commandBuffer.Blit(temp1, blurTex, material, 1);
            commandBuffer.ReleaseTemporaryRT(temp1);
        }
        else if (numberOfPasses == 3)
        {
            commandBuffer.GetTemporaryRT(blurTex, quarter.width, quarter.height, 0, FilterMode.Bilinear);
            int temp1 = Shader.PropertyToID("temp1");
            commandBuffer.GetTemporaryRT(temp1, eighths.width, eighths.height, 0, FilterMode.Bilinear);
            commandBuffer.Blit(BuiltinRenderTextureType.CameraTarget, blurTex, material, 0);
            commandBuffer.Blit(blurTex, temp1, material, 1);
            commandBuffer.Blit(temp1, blurTex, material, 1);
            commandBuffer.ReleaseTemporaryRT(temp1);
        }
        else if (numberOfPasses == 4)
        {
            int temp1 = Shader.PropertyToID("temp1");
            int temp2 = Shader.PropertyToID("temp2");
            commandBuffer.GetTemporaryRT(blurTex, quarter.width, quarter.height, 0, FilterMode.Bilinear);
            commandBuffer.GetTemporaryRT(temp1, eighths.width, eighths.height, 0, FilterMode.Bilinear);
            commandBuffer.GetTemporaryRT(temp2, sixths.width, sixths.height, 0, FilterMode.Bilinear);
            commandBuffer.Blit(BuiltinRenderTextureType.CameraTarget, blurTex, material, 0);
            commandBuffer.Blit(blurTex, temp1, material, 1);
            commandBuffer.Blit(temp1, temp2, material, 1);
            commandBuffer.Blit(temp2, temp1, material, 1);
            commandBuffer.Blit(temp1, blurTex, material, 1);
            commandBuffer.ReleaseTemporaryRT(temp1);
            commandBuffer.ReleaseTemporaryRT(temp2);
        }

        commandBuffer.SetGlobalTexture(bloomTexString, blurTex);
        commandBuffer.ReleaseTemporaryRT(blurTex);

        commandBuffer.Blit(source, BuiltinRenderTextureType.CameraTarget, material, 2);
        commandBuffer.ReleaseTemporaryRT(source);
        camera.forceIntoRenderTexture = true;
        camera.AddCommandBuffer(CameraEvent.BeforeImageEffects, commandBuffer);
    }
}