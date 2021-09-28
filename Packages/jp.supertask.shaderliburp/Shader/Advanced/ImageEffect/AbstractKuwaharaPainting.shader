// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "URP/Advanced/ImageEffect/AbstractKuwaharaPainting"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}

        _KuwaharaRadius ("Kuwahara Radius", Range(0, 10)) = 10
        _SobelLineColor ("Sobel Line Color", Color) = (1,1,1,1)
        _SobelDeltaX ("Delta X", Float) = 0.01
		_SobelDeltaY ("Delta Y", Float) = 0.01
    }
    SubShader
    {
        //Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            //CGPROGRAM
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #pragma multi_compile _ DEBUG_COLORFUL_FRACTAL

            //#include "UnityCG.cginc"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            #include "Packages/jp.supertask.shaderliburp/Shader/Lib/PhotoShopMath.hlsl"
            #include "Packages/jp.supertask.shaderliburp/Shader/Lib/ImageEffect/SobelFilter.hlsl"
            #include "Packages/jp.supertask.shaderliburp/Shader/Lib/ImageEffect/KuwaharaFilter.hlsl"
            #include "Packages/jp.supertask.shaderliburp/Shader/Lib/KeijiroNoise/SimplexNoise2D.hlsl"
            #include "Packages/jp.supertask.shaderliburp/Shader/Lib/KeijiroNoise/ClassicNoise2D.hlsl"
            #include "Packages/jp.supertask.shaderliburp/Shader/Lib/fbm.hlsl"
            
            struct Attributes
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                float4 positionOS   : POSITION;                 
                half2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
                half2 uv : TEXCOORD0;
            }; 

            /*
			struct appdata_t
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half3 normal : NORMAL;
			};
            */
 
            struct v2f {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
            };
 
            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _ColorfulFractalTex;
            float4 _ColorfulFractalTex_ST;
            
            //sampler2D _CameraDepthTexture;
            
            float4 _SobelLineColor;
            float _SobelDeltaX;
            float _SobelDeltaY;
            
/*
            v2f vert(appdata_base v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }
*/

            Varyings vert(Attributes IN)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings OUT;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous space
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                // Returning the output.
                return OUT;
            }

            int _KuwaharaRadius;
            float4 _MainTex_TexelSize;
 
            //float4 frag (v2f i) : SV_Target
            float4 frag (Varyings i) : SV_Target
            {
                half2 uv = i.uv;
#ifdef DEBUG_COLORFUL_FRACTAL
                return tex2Dlod(_ColorfulFractalTex, float4(uv, 0, 0));
#endif

                float4 color;
                KuwaharaFilter_float(_MainTex, _MainTex_TexelSize, uv, _KuwaharaRadius, color);

                float sobelFilter = 0;
                SobelFilter_float(_MainTex, uv, float2(_SobelDeltaX, _SobelDeltaY), sobelFilter);

                float4 lines = _SobelLineColor * sobelFilter;
                lines *= fbm(uv * 10);
                //lines *= SimplexNoise(uv*0.1);
                //return ;
                //return PeriodicNoise(uv*20, float3(10, 10,0));
                
                //bool objExists = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv) > 0;
                //bool objExists = SampleSceneDepth(i.uv) > 0; //Game viewでうまく表示されない
                //bool objExists = true;
                float4 colorFractal = tex2Dlod(_ColorfulFractalTex, float4(uv, 0, 0));
                color.rgb = BlendSoftLight(color.rgb, colorFractal);
                color.rgb = BlendHardLight(color.rgb, lines);
                return color;
            }
            //ENDCG
            ENDHLSL
        }
    }
}