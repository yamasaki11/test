using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization;
using UnityEngine;
using UnityEngine.XR;

//[ExecuteInEditMode]
//[ExecuteAlways]

class OriginalTransformInfo
{
    public void SetInfo(Transform src)
    {
        scale = src.localScale;
        name = src.name;
        position = src.localPosition;
    }

    public void SetTransform(Transform dest)
    {
        dest.localScale = scale;
        dest.localPosition = position;
    }
    public Vector3 scale;
    public string name;
    public Vector3 position;
}
public class SegmentScaleExecutor : MonoBehaviour
{
    // Start is called before the first frame update

    //[SerializeField] private SegmentScale[] parameters ;

    [SerializeField] private Transform RootBone;

    private Transform[] skelton;
    
    private OriginalTransformInfo[] originalInfo;
    
    private Vector3[] result;
    void Start()
    {
        skelton = RootBone.GetComponentsInChildren<Transform>(true);
        if (skelton.Length != 0)
        {
            result = new Vector3[ skelton.Length ];
            originalInfo = new OriginalTransformInfo[ skelton.Length ];
        }

        var i = 0;
        foreach (var bone in skelton)
        {
            
            originalInfo[i] = new OriginalTransformInfo();
            originalInfo[i].SetInfo(bone);
            
            i++;
        }
        
    }

    // Update is called once per frame
    void Update()
    {

        ResetLocalScale();
        ResolveScaleMatrix();
    }

    private OriginalTransformInfo GetOriginalScaleFromName(string name)
    {
        foreach (var info in originalInfo)
        {
            if (info.name == name)
            {
                return info;
            } 
        }

        return null;
    }

    private void ResolveScaleMatrix()
    {
        var i = 0;
        foreach (var bone in skelton)
        {
            var scale = Vector3.one;
            //var finish = false;
            
            var current = bone.parent;
            if (bone.name != RootBone.name)
            {
                var info = GetOriginalScaleFromName(bone.parent.name);
                if (info != null)
                {
                    scale = info.scale;
                }
            }

            //Matrix4x4 ScaleMat = Matrix4x4.Scale(scale);
            var localBoneScale = bone.localScale;
            var inverseLocalScale = new Vector3(localBoneScale.x / scale.x, localBoneScale.y / scale.y,
                localBoneScale.z / scale.z);
            
            result[i] = inverseLocalScale;
            i++;
        }

        i = 0;
        foreach (var bone in skelton)
        {
            bone.localScale = result[i];
            var scaleMatrix = Matrix4x4.Scale(new Vector3(1 / result[i].x, 1 / result[i].y, 1 / result[i].z));
            //bone.localPosition = scaleMatrix.MultiplyPoint(bone.localPosition);
            i++;
        }
    }

    private void ResetLocalScale()
    {
        var i = 0;
        foreach (var bone in skelton)
        {
            originalInfo[i].SetTransform(bone);
            i++;
        }        
    }
    
    private void OnValidate()
    {
        Debug.Log("test");
    }

    /*private void LateUpdate()
    {
        foreach (var param in parameters)
        {
            param.SetScale();
        }
    }*/


    /*private void OnPreRender()
    {
        //Debug.Log("OnPreRender");

        foreach (var param in parameters)
        {
            param.SetScale();

        }
    }*/
    

    private void OnPreCull()
    {

    }

    private void OnPostRender()
    {
        //Debug.Log("OnPostRender");
    }
}
