#version 330

#define OUTLINE_WIDTH 7.0f

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 col_diffuse;

uniform vec2 texture_size;
uniform vec4 outline_color;

out vec4 final_color;

void main()
{
    vec2 padding = vec2(OUTLINE_WIDTH) / texture_size;
    vec2 shrunk_tex_coord = fragTexCoord * (1.0 + padding * 2.0) - padding;

    vec4 texel = vec4(0.0);
    if(shrunk_tex_coord.x >= 0.0 && shrunk_tex_coord.x <= 1.0 && 
       shrunk_tex_coord.y >= 0.0 && shrunk_tex_coord.y <= 1.0) 
    {
        texel = texture(texture0, shrunk_tex_coord);
    }

    vec2 texel_scale = vec2(OUTLINE_WIDTH / texture_size.x, OUTLINE_WIDTH / texture_size.y);

    vec4 corners = vec4(0.0);
    corners.x = texture(texture0, shrunk_tex_coord + vec2(texel_scale.x, texel_scale.y)).a;
    corners.y = texture(texture0, shrunk_tex_coord + vec2(texel_scale.x, -texel_scale.y)).a;
    corners.z = texture(texture0, shrunk_tex_coord + vec2(-texel_scale.x, texel_scale.y)).a;
    corners.w = texture(texture0, shrunk_tex_coord + vec2(-texel_scale.x, -texel_scale.y)).a;

    float outline = min(dot(corners, vec4(1.0)), 1.0);
    vec4 color = mix(vec4(0.0), outline_color, outline);
    final_color = mix(color, texel, texel.a);
}
