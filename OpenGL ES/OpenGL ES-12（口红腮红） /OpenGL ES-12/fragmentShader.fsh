precision mediump float;

varying lowp vec2 varyTextCoord;
uniform sampler2D inputImageTexture;

void main(void) {
    vec4 color = texture2D(inputImageTexture, vec2(varyTextCoord.x, 1.0-varyTextCoord.y));
    gl_FragColor = color;
}
