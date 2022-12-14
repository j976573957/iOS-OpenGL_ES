
attribute vec3 position;
attribute vec2 inputTextureCoordinate;
varying vec2   textureCoordinate;
varying vec2   textureCoordinate2;

void main(void) {
    gl_Position = vec4(position, 1.);
    textureCoordinate = inputTextureCoordinate;
    textureCoordinate2 = position.xy * 0.5 + 0.5;//顶点坐标转换为纹理坐标：公式：（x, y）* 0.5 + 0.5 = (s, t)
}
