using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

//[ExecuteInEditMode]
//[ExecuteAlways]
public class SegmentScaleExecutor : MonoBehaviour
{
    // Start is called before the first frame update

    [SerializeField] private SegmentScale[] parameters ;

    [SerializeField] private Transform RootBone;
    private Vector3[] OriginalScale;
    //private Vector3[] postTransformPosition;
    private Vector3[] OriginalPosition;
    private Transform[] skelton;
    void Start()
    {
        skelton = RootBone.GetComponentsInChildren<Transform>(true);
        if (skelton.Length != 0)
        {
            OriginalScale = new Vector3[ skelton.Length ];
            OriginalPosition = new Vector3[ skelton.Length ];
        }
        //transform.

        var i = 0;
        foreach (var bone in skelton)
        {
            OriginalScale[i] = bone.localScale;
            
            
            OriginalPosition[i] = bone.localPosition;
            //OriginalPosition[i] = bone.position;
            i++;
        }

        //ResolveScaleMatrix();
    }

    // Update is called once per frame
    void Update()
    {

        ResetLocalScale();
        ResolveScaleMatrix();
    }

    private void ResolveScaleMatrix()
    {
        foreach (var bone in skelton)
        {
            var scale = Vector3.one;
            var finish = false;
            
            var current = bone.parent;
            if (bone.name != RootBone.name)
            {
                
                do
                {
                    if (current.name == RootBone.name)
                    {
                        finish = true;
                    }

                    var localScale = current.localScale;
                    scale = new Vector3(localScale.x * scale.x, localScale.y * scale.y, localScale.z * scale.z);
                    current = current.parent;
                } while (finish != true);
                
                //scale = bone.parent.localScale;
            }

            Matrix4x4 ScaleMat = Matrix4x4.Scale(scale);
            var localBoneScale = bone.localScale;
            var inverseLocalScale = new Vector3(localBoneScale.x / scale.x, localBoneScale.y / scale.y,
                localBoneScale.z / scale.z);

            /*if (bone.name == "Character1_Spine")
            {
                Debug.Log(bone.name + bone.localScale);
            }*/
            bone.localScale = inverseLocalScale;
            
            //bone.localPosition = ScaleMat.MultiplyPoint(bone.localPosition);
            //bone.position = ScaleMat.MultiplyPoint(bone.position);
            
        }        
    }

    private void ResetLocalScale()
    {
        var i = 0;
        foreach (var bone in skelton)
        {
            bone.localScale = OriginalScale[i];
            //bone.localPosition = OriginalPosition[i];

            bone.position = OriginalPosition[i];
            i++;
        }        
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
