// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'


Shader "Custom/Glitter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GlitterColor("GlitterColor", COLOR) =(1,1,1,1)
        _GlitterPostContrast("GlitterPostContrast", Range(0, 10.0)) = 1.0
        _GlitterSensitivity("GlitterSensitivity", Range(0, 10.0)) = 1.0
        _GlitterScaleRandomize("GlitterScaleRandomize", Range(0, 1.0))  = 0
        
        _GlitterSizeX("GlitterSizeX", Range(0, 10.0))  = 1
        _GlitterSizeY("GlitterSizeY", Range(0, 10.0))  = 1
        _GlitterScale("GlitterScale", Range(0, 10.0))  = 1
        _GlitterDensity("GlitterDensity", Range(0, 10.0))  = 3
        _GlitterBlinkSpeed("GlitterBlinkSpeed", Range(0, 2.0))  = 0
        _AngleLimit("AngleLimit", Range(0, 2.0))  = 0
        _LightDirection("LightDirection", Range(0, 2.0))  = 0
        _ColorRandomize("ColorRandomize", Range(0, 2.0))  = 0
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Glitter.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal :NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _GlitterColor;
            float4 _MainTex_ST;
            float4 _GlitterParams1;
            float4 _GlitterParams2;
            float _GlitterPostContrast;
            float _GlitterSensitivity;
            float _GlitterScaleRandomize;

            float _GlitterSizeX;
            float _GlitterSizeY;
            float _GlitterScale;
            float _GlitterDensity;
            float _GlitterBlinkSpeed;
            float _AngleLimit;
            float _LightDirection;
            float _ColorRandomize;          

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS  = normalize( UnityObjectToWorldNormal(v.normal) );
                o.positionWS = mul(unity_ObjectToWorld, v.vertex);

                
                return o;
            }

            //#include "Glitter.cginc"
            


            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float3 viewDir = normalize( _WorldSpaceCameraPos - i.positionWS );
                float3 cameraDir = normalize(UNITY_MATRIX_V._m20_m21_m22);
                float3 normalWS = normalize(i.normalWS);
                float4 glitterColor = _GlitterColor;
                
                _GlitterParams1.x = 1/_GlitterSizeX*256;
                _GlitterParams1.y = 1/_GlitterSizeY*256;
                _GlitterParams1.z = _GlitterScale;
                _GlitterParams1.w = 10/_GlitterDensity;

                _GlitterParams2.x = _GlitterBlinkSpeed;
                _GlitterParams2.y = _AngleLimit;
                _GlitterParams2.z = _LightDirection;
                _GlitterParams2.w = _ColorRandomize;


                
                //float4 col = tex2D(_MainTex, i.uv);

                //glitterColor *= col;
                glitterColor.rgb *= lilCalcGlitter(i.uv, normalWS, viewDir, cameraDir, _WorldSpaceLightPos0.xyz, _GlitterParams1, _GlitterParams2,  _GlitterPostContrast, _GlitterSensitivity, _GlitterScaleRandomize, 0, false, float4(0,0,0,0), float4(1,1,0,0));
                

                return glitterColor;
            }
            ENDCG
        }
    }
}
