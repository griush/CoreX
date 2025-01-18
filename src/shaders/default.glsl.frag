#version 410 core

layout(location = 0) out vec4 o_Color;

// uniforms
uniform vec4 u_Color;

in vec2 v_TexCoord;

void main() {
    o_Color = u_Color;
    o_Color = vec4(v_TexCoord, 0.0, 1.0);
}
