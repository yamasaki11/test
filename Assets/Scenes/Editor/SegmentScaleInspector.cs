using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

class TransformInfo
{
    public Vector3 Position;
    public Vector3 Scale;
    public Vector3 Rotation;
}

[CustomEditor(typeof(SegmentScaleExecutor))]
public class SegmentScaleInspector : Editor
{
    private SegmentScaleExecutor segmentScaleExecutor;
    private Transform _rootBone;
    private TransformInfo[] originalInfo;
    private Transform[] _skeleton;
    private void OnEnable()
    {
        
        //Debug.Log("OnEnable");
        segmentScaleExecutor = (SegmentScaleExecutor)target;
        _rootBone = segmentScaleExecutor.RootBone;
        
        //segmentScaleExecutor.Init();
        
        _skeleton = _rootBone.GetComponentsInChildren<Transform>(true);
        if (_skeleton.Length != 0)
        {
            originalInfo = new TransformInfo[ _skeleton.Length ];
        }

        var i = 0;
        foreach (var bone in _skeleton)
        {
            originalInfo[i] = new TransformInfo();
            originalInfo[i].Position = bone.localPosition;
            originalInfo[i].Rotation = bone.localEulerAngles;
            originalInfo[i].Scale = bone.localScale;
            i++;
        }
        
        
    }

    public override void OnInspectorGUI()
    {
        //Debug.Log("OnInspectorGUI");
        serializedObject.Update();
        base.OnInspectorGUI();

        EditorGUILayout.Space();
        EditorGUILayout.Space();
        var i = 0;
        foreach (var info in originalInfo)
        {
            //using (new EditorGUILayout.HorizontalScope()) {
            EditorGUILayout.LabelField(_skeleton[i].name);
            info.Position = EditorGUILayout.Vector3Field("position", info.Position);
            info.Rotation = EditorGUILayout.Vector3Field("rotation", info.Rotation);
            info.Scale = EditorGUILayout.Vector3Field("scale", info.Scale);

            
            _skeleton[i].localPosition = info.Position;
            _skeleton[i].localEulerAngles = info.Rotation;
            _skeleton[i].localScale = info.Scale;
            EditorGUILayout.Space();
            //}

            i++;
        }
        
        segmentScaleExecutor.ResetOriginalInfo();
        segmentScaleExecutor.ResolveScaleMatrix();
        
        serializedObject.ApplyModifiedProperties();
    }
}
