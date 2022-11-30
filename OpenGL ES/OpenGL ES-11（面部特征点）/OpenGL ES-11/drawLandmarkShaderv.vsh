/* 
  drawLandmarkShaderv.vsh
  OpenGL ES-11

  Created by Mac on 2022/11/16.
  
*/
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

