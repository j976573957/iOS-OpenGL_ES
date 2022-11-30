precision highp float;
uniform sampler2D colorMap;
varying highp vec2 varyTextCoord;

void main(){
    vec2 uv = varyTextCoord.xy;
    if (uv.x <= 0.5) {
        uv.x = uv.x * 2.0;
    } else {
        uv.x = (uv.x - 0.5) * 2.0;
    }
    
    if (uv.y <= 1.0/3.0) {
        uv.y = uv.y * 3.0;
    } else if(uv.y > 1.0/3.0 && uv.y <= 2.0/3.0) {
        uv.y = (uv.y - 1.0/3.0) * 3.0;
    }else{
        uv.y = (uv.y - 2.0/3.0) * 3.0;
    }

    
    gl_FragColor = texture2D(colorMap, uv);
}
