precision mediump float;
varying highp vec2 textureCoordinate;
varying highp vec2 textureCoordinate2;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform float intensity;
uniform int blendMode;

float blendHardLight(float base, float blend) {
    return blend<0.5?(2.0*base*blend):(1.0-2.0*(1.0-base)*(1.0-blend));
}

vec3 blendHardLight(vec3 base, vec3 blend) {
    return vec3(blendHardLight(base.r,blend.r),blendHardLight(base.g,blend.g),blendHardLight(base.b,blend.b));
}

float blendSoftLight(float base, float blend) {
    return (blend<0.5)?(base+(2.0*blend-1.0)*(base-base*base)):(base+(2.0*blend-1.0)*(sqrt(base)-base));
}
vec3 blendSoftLight(vec3 base, vec3 blend) {
    return vec3(blendSoftLight(base.r,blend.r),blendSoftLight(base.g,blend.g),blendSoftLight(base.b,blend.b));
}

vec3 blendMultiply(vec3 base, vec3 blend) {
    return base*blend;
}

float blendOverlay(float base, float blend) {
    return base<0.5?(2.0*base*blend):(1.0-2.0*(1.0-base)*(1.0-blend));
}
vec3 blendOverlay(vec3 base, vec3 blend) {
    return vec3(blendOverlay(base.r,blend.r),blendOverlay(base.g,blend.g),blendOverlay(base.b,blend.b));
}

vec3 blendFunc(vec3 base, vec3 blend, int blendMode) {
    if (blendMode == 0) {
        return blend;
    } else if (blendMode == 15) {
        return blendMultiply(base, blend);
    } else if (blendMode == 17) {
        return blendOverlay(base, blend);
    } else if (blendMode == 22) {
        return blendHardLight(base, blend);
    }
    return blend;
}

void main()
{
   vec4 fgColor = texture2D(inputImageTexture2, textureCoordinate);
   fgColor = fgColor * intensity;
   vec4 bgColor = texture2D(inputImageTexture, vec2(textureCoordinate2.x, 1.0 - textureCoordinate2.y));
   if (fgColor.a == 0.0) {
       gl_FragColor = bgColor;
       return;
   }
   
   
   vec3 color = blendFunc(bgColor.rgb, clamp(fgColor.rgb * (1.0 / fgColor.a), 0.0, 1.0), blendMode);
//    color = color * intensity;
   gl_FragColor = vec4(bgColor.rgb * (1.0 - fgColor.a) + color.rgb * fgColor.a, 1.0);
}
