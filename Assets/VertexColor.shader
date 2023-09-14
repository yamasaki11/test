Shader "Custom/VertexColor"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _EmissiveMask("EmisiveMask", 2D) = "white"{}
        [HDR] _EmissiveColor("EmissiveColor", COLOR) = (0,0,0,0)
        _VertexColorWeight ("VertexColorWeight", Range(0,2)) = 1.0
        _StencilRef("StencilRef", Int) = 128
    }
    SubShader
    {
        Stencil
        {
            Ref [_StencilRef]
            Comp always
            Pass replace
        }
        Tags { "RenderType"="Opaque" "Queue"="Geometry+1"}
        
        LOD 200

		CGPROGRAM
		#pragma surface surf Lambert vertex:vert
		#pragma target 3.0

        sampler2D _MainTex;
		sampler2D _EmissiveMask;
		float4 _EmissiveColor;
		float _VertexColorWeight;

        struct Input
        {
            float4 vertColor;
            float2 uv_MainTex;
        };
		

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v, out Input o){
			UNITY_INITIALIZE_OUTPUT(Input, o);
            o.uv_MainTex = v.texcoord;
			o.vertColor = v.color;
		}
        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * IN.vertColor * _VertexColorWeight;
            o.Emission = tex2D (_EmissiveMask, IN.uv_MainTex)*_EmissiveColor;
            o.Albedo = c.rgb;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
