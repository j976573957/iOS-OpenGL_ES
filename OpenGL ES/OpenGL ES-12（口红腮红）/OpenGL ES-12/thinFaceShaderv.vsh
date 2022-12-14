/* 
  thinFaceShaderv.vsh
  OpenGL ES-12

  Created by Mac on 2022/11/18.
  
*/
attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 textureCoordinate;

void main()
{
    gl_Position = position;
    textureCoordinate = vec2(inputTextureCoordinate.x, 1.0-inputTextureCoordinate.y);
}
