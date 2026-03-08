#version 330

#define OUTLINE_WIDTH 4.0f

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 col_diffuse;

uniform vec2 texture_size;
uniform vec4 outline_color;

out vec4 final_color;

void main()
{
    vec4 texel = texture(texture0, fragTexCoord);
    vec2 texel_scale = vec2(0.0);
    texel_scale.x = OUTLINE_WIDTH / texture_size.x;
    texel_scale.y = OUTLINE_WIDTH / texture_size.y;

    vec4 corners = vec4(0.0);
    corners.x = texture(texture0, fragTexCoord + vec2(texel_scale.x, texel_scale.y)).a;
    corners.y = texture(texture0, fragTexCoord + vec2(texel_scale.x, -texel_scale.y)).a;
    corners.z = texture(texture0, fragTexCoord + vec2(-texel_scale.x, texel_scale.y)).a;
    corners.w = texture(texture0, fragTexCoord + vec2(-texel_scale.x, -texel_scale.y)).a;

    float outline = min(dot(corners, vec4(1.0)), 1.0);
    vec4 color = mix(vec4(0.0), outline_color, outline);
    final_color = mix(color, texel, texel.a);
}
