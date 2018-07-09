Shader "Unlit/Test2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _LightMapTex("LightMap Texture", 2D) = "white" {}
        _Color("Color", Color) = (0.9313725, 0.9313725, 0.9313725, 0.95)
        
        _LightArea("LightArea", Float) = 0.51
        _SecondShadow("SecondShadow", Float) = 0.51
        _FirstShadowMultColor("FirstShadowMultColor", Color) = (0.7294118, 0.6, 0.6509804, 1.0)
        _SecondShadowMultColor("SecondShadowMultColor", Color) = (0.6509804, 0.4509804, 0.5490196, 1.0)

        _LightSpecColor("LightSpecColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _Shininess("Shininess", Float) = 10
        _SpecMulti("SpecMulti", Float) = 0.2 
    }
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
            Tags{ "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

			struct appdata
			{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
                float3 normal : NORMAL;
			};

			struct v2f
			{
                float4  vertex   : SV_POSITION;

                fixed3  color0 : COLOR0;
                fixed   color1 : COLOR1;

                float2  uv          : TEXCOORD0;
                float3  worldNormal : TEXCOORD1;
                float3  worldPos    : TEXCOORD2;
			};

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _LightMapTex;
            
            fixed4 _Color;

            float _LightArea;
            float _SecondShadow;
            fixed4 _FirstShadowMultColor;
            fixed4 _SecondShadowMultColor;

            fixed4 _LightSpecColor;
            float _Shininess;
            float _SpecMulti;
			
			v2f vert (appdata v)
			{
				v2f o;
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.color0 = v.color.bgr;
                o.color1 = saturate(dot(o.worldNormal, normalize(_WorldSpaceLightPos0))) * 0.5 + 0.5;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 mainTexCol = tex2D(_MainTex, i.uv);
                fixed4 lightMapCol = tex2D(_LightMapTex, i.uv);
                fixed3 firstShadowCol = mainTexCol.rgb * _FirstShadowMultColor.rgb;
                fixed3 secondShadowCol = mainTexCol.rgb * _SecondShadowMultColor.rgb;
                int shadowColCheckValue = max(floor((i.color0.r * lightMapCol.g + i.color1) * 0.5 - _SecondShadow + 1.0), 0);
                fixed3 shadowCol = (shadowColCheckValue != 0) ? firstShadowCol : secondShadowCol;
                float checkValue1 = max(floor(0.91 + i.color0.r * lightMapCol.g), 0.0);
                float checkValue2 = max(floor(1.5 - i.color0.r * lightMapCol.g), 0.0);

                float rgValue = i.color0.r * lightMapCol.g;
                float2 tempVec2 = float2(rgValue, rgValue) * float2(1.2, 1.25) + float2(-0.1, -0.125);
                float rgValuePlus = ((int)checkValue2 != 0) ? tempVec2.y : tempVec2.x;
                rgValuePlus = max(floor((rgValuePlus + i.color1) * 0.5 - _LightArea + 1.0), 0.0);

                firstShadowCol = ((int)rgValuePlus != 0) ? mainTexCol.rgb : firstShadowCol;
                fixed3 diffuseCol = ((int)checkValue1 != 0) ? firstShadowCol : shadowCol;
                //-----------------------------------------------------------------------

                float3 worldNormal = normalize(i.worldNormal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 halfDir = normalize(_WorldSpaceLightPos0.xyz + viewDir);

                float check1 = max(dot(worldNormal, halfDir), 0.0);
                check1 = pow(check1, _Shininess);
                float check2 = max(floor(1.0 - lightMapCol.b - check1 + 1.0), 0.0);

                fixed3 specCol = _LightSpecColor.rgb * _SpecMulti * lightMapCol.r;
                specCol = ((int)check2 != 0) ? fixed3(0, 0, 0) : specCol;
                return fixed4(diffuseCol.rgb + specCol,1);
                //fixed3 finCol = lerp(diffuseCol.rgb, mainTexCol.rgb, mainTexCol.a);
                //return fixed4(finCol + specCol, 1);

				
			}
			ENDCG
		}
	}
}
