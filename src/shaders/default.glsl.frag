#version 410 core

out vec4 o_Color;

uniform vec4 u_Color;

void main() {
    o_Color = u_Color * vec4(1.0, 1.0, 1.0, 1.0);
}
