shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 water_color : source_color = vec4(0.025, 0.22, 0.34, 0.82);
uniform vec4 crest_color : source_color = vec4(0.10, 0.65, 0.95, 0.5);
uniform float wave_scale = 3.2;
uniform float wave_speed = 0.38;
uniform float ripple_strength = 0.18;
uniform float fresnel_strength = 0.34;

void fragment() {
    vec2 uv_a = UV * wave_scale + vec2(TIME * wave_speed, TIME * -wave_speed * 0.36);
    vec2 uv_b = UV * (wave_scale * 1.65) + vec2(TIME * -wave_speed * 0.72, TIME * wave_speed * 0.5);
    vec2 uv_c = UV * (wave_scale * 3.4) + vec2(TIME * 0.16, TIME * -0.22);

    float wave_a = sin(uv_a.x * 5.2 + sin(uv_a.y * 3.0));
    float wave_b = cos(uv_b.y * 4.2 + sin(uv_b.x * 2.4));
    float wave_c = sin(uv_c.x * 8.0 + cos(uv_c.y * 6.2));
    float crest = smoothstep(0.45, 0.94, (wave_a + wave_b) * 0.5 + wave_c * 0.12);
    float ripple = smoothstep(0.62, 0.98, sin(uv_c.y * 3.7 + wave_a * 0.8));
    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.4);

    float highlight = clamp(crest * ripple_strength + fresnel * fresnel_strength + ripple * 0.08, 0.0, 0.58);
    ALBEDO = mix(water_color.rgb, crest_color.rgb, highlight);
    METALLIC = 0.68;
    ROUGHNESS = mix(0.16, 0.42, clamp(crest + ripple * 0.22, 0.0, 1.0));
    SPECULAR = 0.82;
    EMISSION = crest_color.rgb * (crest * 0.12 + fresnel * 0.2);
    ALPHA = water_color.a;
}
