#version 330 core

layout(location = 0) out vec4 FragColor;

uniform vec4 u_Color;
in vec4 vertColor;

void main()
{
    FragColor = vertColor * u_Color;
}