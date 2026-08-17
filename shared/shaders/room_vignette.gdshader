shader_type canvas_item;

uniform float edge_start : hint_range(0.0, 1.0) = 0.6;
uniform float edge_end : hint_range(0.0, 1.0) = 0.94;
uniform float darkness : hint_range(0.0, 1.0) = 1;

void fragment() {
	vec2 d = abs(UV - vec2(0.5)) * 2.0;
	float m = max(d.x, d.y);
	float vig = smoothstep(edge_start, edge_end, m);
	COLOR = vec4(0.0, 0.0, 0.0, vig * darkness);
}
