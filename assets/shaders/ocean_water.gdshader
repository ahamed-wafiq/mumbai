shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Mumbai Drive - Arabian Sea Coastal Water Shader
// Realistic moving waves, coastal depth gradient, specular sun glint & surf

uniform vec4 deep_color : source_color = vec4(0.03, 0.12, 0.24, 0.96);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.34, 0.48, 0.92);
uniform vec4 foam_color : source_color = vec4(0.85, 0.92, 0.98, 1.0);

uniform float wave_speed : hint_range(0.1, 2.0) = 0.65;
uniform float wave_scale : hint_range(0.01, 0.5) = 0.08;
uniform float wave_height : hint_range(0.0, 1.5) = 0.25;

uniform float roughness_val : hint_range(0.0, 1.0) = 0.08;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.65;

varying vec3 v_world_pos;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Dual trochoidal wave displacement
    float time = TIME * wave_speed;
    float w1 = sin((v_world_pos.x * wave_scale * 0.7) + (v_world_pos.z * wave_scale) + time);
    float w2 = cos((v_world_pos.x * wave_scale * 1.3) - (v_world_pos.z * wave_scale * 0.8) + (time * 1.2));
    
    VERTEX.y += (w1 + w2) * 0.5 * wave_height;
}

void fragment() {
    float time = TIME * wave_speed;
    
    // Wave normal perturbations
    float n1 = sin((v_world_pos.x * 0.2) + (v_world_pos.z * 0.3) + time);
    float n2 = cos((v_world_pos.x * 0.35) - (v_world_pos.z * 0.25) + time * 1.3);
    vec3 wave_normal = normalize(vec3(n1 * 0.15, 1.0, n2 * 0.15));
    NORMAL = (VIEW_MATRIX * vec4(wave_normal, 0.0)).xyz;
    
    // Depth gradient based on distance from the Marine Drive seawall (X ~ -14m)
    // As X approaches -14m (near shore), water is shallower turquoise; further west (X < -100m) is deep navy
    float dist_from_shore = clamp((-v_world_pos.x - 14.0) / 120.0, 0.0, 1.0);
    vec3 water_col = mix(shallow_color.rgb, deep_color.rgb, dist_from_shore);
    
    // Coastal surf / white foam near the seawall barrier
    float shore_proximity = clamp(1.0 - ((-v_world_pos.x - 14.0) / 6.0), 0.0, 1.0);
    float foam_crest = clamp((n1 + n2) * 0.5 + shore_proximity * 0.8 - 0.5, 0.0, 1.0);
    water_col = mix(water_col, foam_color.rgb, foam_crest * 0.65);
    
    ALBEDO = water_col;
    ROUGHNESS = roughness_val + (foam_crest * 0.4);
    METALLIC = metallic_val;
    SPECULAR = 0.85;
}
