// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'


Shader "Unlit/glitter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GlitterColor("GlitterColor", COLOR) =(1,1,1,1)
        //_GlitterParams1("_GlitterParams1", Vector) = (256,256,0.16,50)
        //_GlitterParams2("_GlitterParams2", Vector) = (0.25,0,0,0)
        _GlitterPostContrast("_GlitterPostContrast", Float) = 1.0
        _GlitterSensitivity("_GlitterSensitivity", Float) = 1.0
        _GlitterScaleRandomize("_GlitterScaleRandomize", Range(0, 1.0))  = 0
        
        _GlitterSizeX("_GlitterSizeX", Range(0, 10.0))  = 1
        _GlitterSizeY("_GlitterSizeY", Range(0, 10.0))  = 1
        _GlitterScale("_GlitterScale", Range(0, 10.0))  = 1
        _GlitterDensity("_GlitterDensity", Range(0, 100.0))  = 50
        _GlitterBlinkSpeed("_GlitterBlinkSpeed", Range(0, 2.0))  = 0
        _AngleLimit("_AngleLimit", Range(0, 2.0))  = 0
        _LightDirection("_LightDirection", Range(0, 2.0))  = 0
        _ColorRandomize("_ColorRandomize", Range(0, 2.0))  = 0
        //_GlitterShapeTex("_GlitterShapeTex", 2D) = "white" {}
        
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
            
            // Simplest Fastest 2D Hash
            // https://www.shadertoy.com/view/MdcfDj
            void lilHashRGB4(float2 pos, out float3 noise0, out float3 noise1, out float3 noise2, out float3 noise3)
            {
                // Hash
                // https://www.shadertoy.com/view/MdcfDj
                #define M1 1597334677U
                #define M2 3812015801U
                #define M3 2912667907U
                uint2 q = (uint2)pos;
                uint4 q2 = uint4(q.x, q.y, q.x+1, q.y+1) * uint4(M1, M2, M1, M2);
                uint3 n0 = (q2.x ^ q2.y) * uint3(M1, M2, M3);
                uint3 n1 = (q2.z ^ q2.y) * uint3(M1, M2, M3);
                uint3 n2 = (q2.x ^ q2.w) * uint3(M1, M2, M3);
                uint3 n3 = (q2.z ^ q2.w) * uint3(M1, M2, M3);
                noise0 = float3(n0) * (1.0/float(0xffffffffU));
                noise1 = float3(n1) * (1.0/float(0xffffffffU));
                noise2 = float3(n2) * (1.0/float(0xffffffffU));
                noise3 = float3(n3) * (1.0/float(0xffffffffU));
                #undef M1
                #undef M2
                #undef M3
            }
            float lilNsqDistance(float2 a, float2 b)
            {
                return dot(a-b,a-b);
            }
            float4 lilVoronoi(float2 pos, out float2 nearoffset, float scaleRandomize)
            {
                #if defined(SHADER_API_D3D9) || defined(SHADER_API_D3D11_9X)
                    #define M1 46203.4357
                    #define M2 21091.5327
                    #define M3 35771.1966
                    float2 q = trunc(pos);
                    float4 q2 = float4(q.x, q.y, q.x+1, q.y+1);
                    float3 noise0 = frac(sin(dot(q2.xy,float2(12.9898,78.233))) * float3(M1, M2, M3));
                    float3 noise1 = frac(sin(dot(q2.zy,float2(12.9898,78.233))) * float3(M1, M2, M3));
                    float3 noise2 = frac(sin(dot(q2.xw,float2(12.9898,78.233))) * float3(M1, M2, M3));
                    float3 noise3 = frac(sin(dot(q2.zw,float2(12.9898,78.233))) * float3(M1, M2, M3));
                    #undef M1
                    #undef M2
                    #undef M3
                #else
                    float3 noise0, noise1, noise2, noise3;
                    lilHashRGB4(pos, noise0, noise1, noise2, noise3);
                #endif

                // Get the nearest position
                float4 fracpos = frac(pos).xyxy + float4(0.5,0.5,-0.5,-0.5);
                float4 dist4 = float4(lilNsqDistance(fracpos.xy,noise0.xy), lilNsqDistance(fracpos.zy,noise1.xy), lilNsqDistance(fracpos.xw,noise2.xy), lilNsqDistance(fracpos.zw,noise3.xy));
                dist4 = lerp(dist4, dist4 / max(float4(noise0.z, noise1.z, noise2.z, noise3.z), 0.001), scaleRandomize);

                float3 nearoffset0 = dist4.x < dist4.y ? float3(0,0,dist4.x) : float3(1,0,dist4.y);
                float3 nearoffset1 = dist4.z < dist4.w ? float3(0,1,dist4.z) : float3(1,1,dist4.w);
                nearoffset = nearoffset0.z < nearoffset1.z ? nearoffset0.xy : nearoffset1.xy;

                float4 near0 = dist4.x < dist4.y ? float4(noise0,dist4.x) : float4(noise1,dist4.y);
                float4 near1 = dist4.z < dist4.w ? float4(noise2,dist4.z) : float4(noise3,dist4.w);
                return near0.w < near1.w ? near0 : near1;
            }
            
            float3 lilCalcGlitter(float2 uv, float3 normalDirection, float3 viewDirection, float3 cameraDirection, float3 lightDirection, float4 glitterParams1, float4 glitterParams2, float glitterPostContrast, float glitterSensitivity, float glitterScaleRandomize, uint glitterAngleRandomize, bool glitterApplyShape, float4 glitterShapeTex_ST, float4 glitterAtras)
            {
                // glitterParams1
                // x: Scale, y: Scale, z: Size, w: Contrast
                // glitterParams2
                // x: Speed, y: Angle, z: Light Direction, w:

                #define GLITTER_DEBUG_MODE 0
                #define GLITTER_MIPMAP 1
                #define GLITTER_ANTIALIAS 1

                #if GLITTER_MIPMAP == 1
                    float2 pos = uv * glitterParams1.xy;
                    float2 dd = fwidth(pos);
                    float factor = frac(sin(dot(floor(pos/floor(dd + 3.0)),float2(12.9898,78.233))) * 46203.4357) + 0.5;
                    float2 factor2 = floor(dd + factor * 0.5);
                    pos = pos/max(1.0,factor2) + glitterParams1.xy * factor2;
                #else
                    float2 pos = uv * glitterParams1.xy + glitterParams1.xy;
                #endif
                float2 nearoffset;
                float4 near = lilVoronoi(pos, nearoffset, glitterScaleRandomize);
                

                #if GLITTER_DEBUG_MODE == 1
                    // Voronoi
                    return near.x;
                #else
                    // Glitter
                    float3 glitterNormal = abs(frac(near.xyz*14.274 + _Time.x * glitterParams2.x) * 2.0 - 1.0);
                    glitterNormal = normalize(glitterNormal * 2.0 - 1.0);
                    float glitter = dot(glitterNormal, cameraDirection);
                    glitter = abs(frac(glitter * glitterSensitivity + glitterSensitivity) - 0.5) * 4.0 - 1.0;
                    glitter = saturate(1.0 - (glitter * glitterParams1.w + glitterParams1.w));
                    glitter = pow(glitter, glitterPostContrast);
                    // Circle
                    #if GLITTER_ANTIALIAS == 1
                        glitter *= saturate((glitterParams1.z-near.w) / fwidth(near.w));
                    #else
                        glitter = near.w < glitterParams1.z ? glitter : 0.0;
                    #endif
                    // Angle
                    float3 halfDirection = normalize(viewDirection + lightDirection * glitterParams2.z);
                    float nh = saturate(dot(normalDirection, halfDirection));
                    glitter = saturate(glitter * saturate(nh * glitterParams2.y + 1.0 - glitterParams2.y));
                    // Random Color
                    float3 glitterColor = glitter - glitter * frac(near.xyz*278.436) * glitterParams2.w;
/*                
                    // Shape
                    #if defined(LIL_FEATURE_GlitterShapeTex)
                        if(glitterApplyShape)
                        {
                            float2 maskUV = pos - floor(pos) - nearoffset + 0.5 - near.xy;
                            maskUV = maskUV / glitterParams1.z * glitterShapeTex_ST.xy + glitterShapeTex_ST.zw;
                            if(glitterAngleRandomize)
                            {
                                float si,co;
                                sincos(near.z * 785.238, si, co);
                                maskUV = float2(
                                    maskUV.x * co - maskUV.y * si,
                                    maskUV.x * si + maskUV.y * co
                                );
                            }
                            float randomScale = lerp(1.0, 1.0 / sqrt(max(near.z, 0.001)), glitterScaleRandomize);
                            maskUV = maskUV * randomScale + 0.5;
                            bool clamp = maskUV.x == saturate(maskUV.x) && maskUV.y == saturate(maskUV.y);
                            maskUV = (maskUV + floor(near.xy * glitterAtras.xy)) / glitterAtras.xy;
                            float2 mipfactor = 0.125 / glitterParams1.z * glitterAtras.xy * glitterShapeTex_ST.xy * randomScale;
                            float4 shapeTex = LIL_SAMPLE_2D_GRAD(glitterShapeTex, lil_sampler_linear_clamp, maskUV, abs(ddx(pos)) * mipfactor.x, abs(ddy(pos)) * mipfactor.y);
                            shapeTex.a = clamp ? shapeTex.a : 0;
                            glitterColor *= shapeTex.rgb * shapeTex.a;
                        }
                    #endif
*/                    
                    return glitterColor;
                #endif
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float3 viewDir = normalize( _WorldSpaceCameraPos - i.positionWS );
                float3 cameraDir = normalize(UNITY_MATRIX_V._m20_m21_m22);
                float3 normalWS = normalize(i.normalWS);
                float4 glitterColor = _GlitterColor;
                
                _GlitterParams1.x = _GlitterSizeX*256;
                _GlitterParams1.y = _GlitterSizeY*256;
                _GlitterParams1.z = _GlitterScale;
                _GlitterParams1.w = _GlitterDensity;

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
