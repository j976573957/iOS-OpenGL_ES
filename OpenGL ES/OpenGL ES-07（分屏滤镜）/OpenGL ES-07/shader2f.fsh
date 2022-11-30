precision mediump float; //通过precision关键字来指定默认精度，这样就不用每一个变量前面都声明精度限定符了

varying lowp vec2 varyTextCoord; //顶点着色器传递过来的纹理坐标

uniform sampler2D colorMap; //纹理

void main()
{
    //利用一个临时的二维向量，获取到纹理坐标
    vec2 uv = varyTextCoord.xy;
    float x;
    if (uv.x >= 0.0 && uv.x <= 0.5) {
        // 将x坐标的值映射为0.25~0.75
        x = uv.x + 0.25;
    } else {
        x = uv.x - 0.25;
    }
    //获取纹素
    gl_FragColor = texture2D(colorMap, vec2(x, uv.y));
    //由于y的值没有变，不需要再设y的值
}

/*
 //上下二分屏
 void main()
 {
     //利用一个临时的二维向量，获取到纹理坐标
     vec2 uv = varyTextCoord.xy;
     float y;
     if (uv.y >= 0.0 && uv.y <= 0.5) {
         // 将Y坐标的值映射为0.45~0.95
         y = uv.y + 0.45;
     } else {
         y = uv.y - 0.05;
     }
     //获取纹素
     gl_FragColor = texture2D(colorMap, vec2(uv.x, y));
     //由于X的值没有变，不需要再设y的值
 }
 
 */
