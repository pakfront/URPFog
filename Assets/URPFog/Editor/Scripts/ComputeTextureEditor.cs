using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(ComputeTexture), true)]
public class ComputeTextureEditor: Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        ComputeTexture myScript = (ComputeTexture)target;
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