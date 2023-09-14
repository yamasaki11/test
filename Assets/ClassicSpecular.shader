Shader "Custom/ClassicSpecular"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ReflectionMap("ReflectionMap", CUBE) = "white" {}
        _Spec1Power("Specular Power", Range(0, 100)) = 1
        _Spec1Color("Specular Color", Color) = (0.5,0.5,0.5,1)
        _ReflectionStrength("Reflection Strength", Range(0, 1)) = 0.5
        //_Reflection("Reflection", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{
				"LightMode" = "ForwardBase"
			}

			Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            //#pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 vertexW: TEXCOORD0;
                float2 uv     : TEXCOORD1;
                float3 normal : TEXCOORD2;
            };

            sampler2D _MainTex;
            UNITY_DECLARE_TEXCUBE(_ReflectionMap);
            float4 _MainTex_ST;
            uniform float _Spec1Power;
            uniform float4 _Spec1Color;
            uniform float _ReflectionStrength;
            //uniform float _Reflection;
            
            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertexW = mul(unity_ObjectToWorld, v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);                
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(_WorldSpaceCameraPos -i.vertexW.xyz);
                float3 N = i.normal;
                //float3 H = normalize(L+V);


                // texture albedo
                float4 tex = tex2D(_MainTex, i.uv);

                // Diffuse(HalfLambert)
                float3 NdotL = dot(N, L);
                float3 diffuse = (NdotL*0.5 + 0.5) * _LightColor0.rgb ;

                // Speculer
                half3 reflDir = reflect(-V, i.normal);

                float3 Iblcol = UNITY_SAMPLE_TEXCUBE( _ReflectionMap, reflDir)*_ReflectionStrength;
                //float3 specol = lerp(_Spec1Color, reflcol, _Reflection);
                //float3 specular = pow(max(0.0, dot(H, N)), _Spec1Power) * _Spec1Color;  // reflection
                float3 specular = pow(max(0.0, dot(reflect(-L, N), V)), _Spec1Power) * _Spec1Color.xyz;
                specular = lerp(specular, Iblcol, 0.5);

                float3 col = diffuse*tex + specular;
                //return float4(col.r, col.g, col.b, 1.0);
                return float4(Iblcol.r, Iblcol.g, Iblcol.b, 1.0);
            }
            ENDCG
        }
    }
}
