shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 water_color : source_color = vec4(0.025, 0.22, 0.34, 0.82);
uniform vec4 crest_color : source_color = vec4(0.10, 0.65, 0.95, 0.5);
uniform float wave_scale = 3.2;
uniform float wave_speed = 0.38;
uniform float ripple_strength = 0.12;

void fragment() {
    vec2 uv_a = UV * wave_scale + vec2(TIME * wave_speed, TIME * -wave_speed * 0.36);
    vec2 uv_b = UV * (wave_scale * 1.65) + vec2(TIME * -wave_speed * 0.72, TIME * wave_speed * 0.5);
    float wave_a = sin(uv_a.x * 5.2 + sin(uv_a.y * 3.0));
    float wave_b = cos(uv_b.y * 4.2 + sin(uv_b.x * 2.4));
    float crest = smoothstep(0.55, 0.95, (wave_a + wave_b) * 0.5);
    ALBEDO = mix(water_color.rgb, crest_color.rgb, crest * ripple_strength);
    METALLIC = 0.58;
    ROUGHNESS = mix(0.2, 0.36, crest);
    SPECULAR = 0.7;
    ALPHA = water_color.a;
    EMISSION = crest_color.rgb * crest * 0.16;
}
