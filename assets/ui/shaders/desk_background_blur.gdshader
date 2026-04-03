shader_type canvas_item;

uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform float blur_strength : hint_range(0.0, 3.0) = 1.35;

vec2 safe_uv(vec2 uv) {
	return clamp(uv, vec2(0.001, 0.001), vec2(0.999, 0.999));
}

void fragment() {
	vec2 uv = safe_uv(UV + uv_offset);
	vec2 blur = TEXTURE_PIXEL_SIZE * blur_strength * 2.0;
	vec4 color = vec4(0.0);
	color += texture(TEXTURE, safe_uv(uv + vec2(-blur.x, -blur.y)));
	color += texture(TEXTURE, safe_uv(uv + vec2(0.0, -blur.y)));
	color += texture(TEXTURE, safe_uv(uv + vec2(blur.x, -blur.y)));
	color += texture(TEXTURE, safe_uv(uv + vec2(-blur.x, 0.0)));
	color += texture(TEXTURE, safe_uv(uv));
	color += texture(TEXTURE, safe_uv(uv + vec2(blur.x, 0.0)));
	color += texture(TEXTURE, safe_uv(uv + vec2(-blur.x, blur.y)));
	color += texture(TEXTURE, safe_uv(uv + vec2(0.0, blur.y)));
	color += texture(TEXTURE, safe_uv(uv + vec2(blur.x, blur.y)));
	COLOR = color / 9.0;
}