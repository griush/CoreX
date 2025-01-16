#version 410 core

in vec3 a_Position;

// uniforms
uniform mat4 u_ViewProj;
uniform mat4 u_Model;

void main() {
    gl_Position = u_ViewProj * u_Model * vec4(a_Position, 1.0);
}
