precision highp float;
uniform sampler2D colorMap;
varying highp vec2 varyTextCoord;

void main(){
    vec2 uv = varyTextCoord.xy;
    float a;
    float b = uv.x;
    if (b <= 0.5) {
        a = b * 2.0;
    } else {
        a = (b - 0.5) * 2.0;
    }
    uv.x = a;
    
    if (uv.y <= 0.5) {
        uv.y = uv.y * 2.0;
    } else {
        uv.y = (uv.y - 0.5) * 2.0;
    }
    gl_FragColor = texture2D(colorMap, uv);
}
