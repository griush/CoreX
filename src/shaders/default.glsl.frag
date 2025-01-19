#version 430 core

layout(location = 0) out vec4 o_Color;

// uniforms
uniform sampler2D u_Texture;
uniform vec4 u_Color;

in vec2 v_TexCoord;

void main() {
    o_Color = u_Color * texture(u_Texture, v_TexCoord);
}
