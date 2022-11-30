attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 textureCoordinate;
uniform float sizeScale;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
    gl_PointSize = sizeScale;
}
