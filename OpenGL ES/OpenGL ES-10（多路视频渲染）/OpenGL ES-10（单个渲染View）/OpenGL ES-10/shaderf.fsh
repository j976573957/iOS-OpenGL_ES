precision mediump float; //通过precision关键字来指定默认精度，这样就不用每一个变量前面都声明精度限定符了
// 灰度图像转换的709亮度值
const vec4 kRec709Luma = vec4(0.213, 0.715, 0.072, 1.0);

varying lowp vec2 varyTextCoord; //顶点着色器传递过来的纹理坐标

uniform sampler2D texture1; //纹理1
uniform sampler2D texture2; //纹理2
uniform sampler2D texture3; //纹理3
uniform sampler2D texture4; //纹理4

void main()
{
    vec2 uv = varyTextCoord.xy;
    float a;
    float b = uv.x;
    float c = uv.y;
    if (b <= 0.5) {//左
        a = b * 2.0;
    } else {//右
        a = (b - 0.5) * 2.0;
    }
    uv.x = a;
    
    if (uv.y <= 0.5) {//上
        uv.y = uv.y * 2.0;
    } else {//下
        uv.y = (uv.y - 0.5) * 2.0;
    }
    
    
    if (b <= 0.5) {
        if (c > 0.5) {//左下
            gl_FragColor = texture2D(texture1, uv);
        } else {//左上
            gl_FragColor = texture2D(texture2, uv);
        }
    } else {
        if (c > 0.5) {//右下
            gl_FragColor = texture2D(texture3, uv);
        } else {//右上
            gl_FragColor = texture2D(texture4, uv);
        }
    }
}


