precision mediump float;

varying lowp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;

void main(void) {
    vec4 color = texture2D(inputImageTexture, textureCoordinate);
    gl_FragColor = color;
}
