shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment()
{
	vec4 texture_color = texture(TEXTURE, UV);

	COLOR = mix(texture_color, vec4(1.0), flash_amount);

	COLOR.a = texture_color.a;
}