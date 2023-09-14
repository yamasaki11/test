using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.PlayerLoop;

[ExecuteInEditMode]
public class SegmentScale : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField] private Vector3 Scale = new Vector3(1, 1, 1);

    private Vector3 originalScale;
    void Start()
    {
        originalScale = this.transform.localScale;
    }


    public void SetScale()
    {
        //Debug.Log(Scale);
        this.transform.localScale = new Vector3(Scale.x , Scale.y , Scale.z);
    }

    public void ResetScale()
    {
        this.transform.localScale = originalScale;
        
    }
    
    // Update is called once per frame
    void Update()
    {
        //this.transform.localScale = originalScale;
    }

    private void LateUpdate()
    {
        //var localsScale = this.transform.localScale;
        //this.transform.localScale = new Vector3(Scale.x , Scale.y , Scale.z);
        
    }

    private void OnPreRender()
    {
        Debug.Log("OnPreRender");
        this.transform.localScale = new Vector3(Scale.x , Scale.y , Scale.z);
        //this.transform.localScale = originalScale;
        //throw new NotImplementedException();
    }

    private void OnPostRender()
    {
        Debug.Log("OnPostRender");
        this.transform.localScale = originalScale;
    }
}
