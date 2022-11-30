precision highp float;
uniform sampler2D colorMap;
varying highp vec2 varyTextCoord;

void main() {
    vec2 uv = varyTextCoord.xy;
    if (uv.y >= 0.0 && uv.y < 1.0/3.0) {
        //下边
        uv.y = uv.y + 2.0/3.0 - 0.05;
    } else if(uv.y >2.0/3.0){
        //上边
        uv.y = uv.y - 0.05;
    } else {
        //中间
        uv.y = uv.y + 1.0/3.0 - 0.05;
    }
    gl_FragColor = texture2D(colorMap, uv);
}
