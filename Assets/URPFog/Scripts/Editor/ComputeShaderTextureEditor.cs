using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(ComputeShaderTexture), true)]
public class ComputeShaderTextureEditor: Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        ComputeShaderTexture myScript = (ComputeShaderTexture)target;
        if (GUILayout.Button("Clear"))
        {
            myScript.Clear();
        }
        if (GUILayout.Button("Generate on GPU"))
        {
            myScript.Generate();
        }
        if (GUILayout.Button("Regenerate on GPU"))
        {
            myScript.Regenerate();
        }

        if (GUILayout.Button("Generate and Save Asset"))
        {
            myScript.Generate();
            myScript.SaveAsset();
        }
    }
}