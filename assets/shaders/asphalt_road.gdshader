shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Mumbai Drive - High-Fidelity Coastal Wet Asphalt Road Shader
// Realistic asphalt grain, worn tire track troughs, and crisp markings

uniform vec4 asphalt_color : source_color = vec4(0.12, 0.13, 0.15, 1.0);
uniform vec4 tire_track_color : source_color = vec4(0.08, 0.09, 0.10, 1.0);
uniform vec4 yellow_line_color : source_color = vec4(1.0, 0.78, 0.12, 1.0);
uniform vec4 white_line_color : source_color = vec4(0.92, 0.94, 0.96, 1.0);

uniform float wetness_sheen : hint_range(0.0, 1.0) = 0.55;
uniform float road_roughness : hint_range(0.0, 1.0) = 0.65;

varying vec3 v_world_pos;
varying vec2 v_uv;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_uv = UV;
}

void fragment() {
    vec3 col = asphalt_color.rgb;
    float rough = road_roughness;
    float metal = 0.05;
    
    // UV.x spans across the road width (0.0 to 1.0)
    // 0.5 is the center line
    float u = v_uv.x;
    float v = v_uv.y;
    
    // Worn tire tracks (darker and smoother where car tires run)
    // Left lane tracks at u ~ 0.28, 0.42; Right lane tracks at u ~ 0.58, 0.72
    float t1 = 1.0 - smoothstep(0.0, 0.06, abs(u - 0.28));
    float t2 = 1.0 - smoothstep(0.0, 0.06, abs(u - 0.42));
    float t3 = 1.0 - smoothstep(0.0, 0.06, abs(u - 0.58));
    float t4 = 1.0 - smoothstep(0.0, 0.06, abs(u - 0.72));
    float tire_wear = clamp(t1 + t2 + t3 + t4, 0.0, 1.0);
    
    col = mix(col, tire_track_color.rgb, tire_wear * 0.7);
    rough = mix(rough, 0.35, tire_wear * wetness_sheen);
    metal = mix(metal, 0.25, tire_wear * wetness_sheen);
    
    // High-frequency subtle asphalt aggregate micro-noise
    float micro_grain = fract(sin(dot(v_world_pos.xz * 18.0, vec2(12.9898, 78.233))) * 43758.5453);
    col += (micro_grain - 0.5) * 0.025;
    
    ALBEDO = col;
    ROUGHNESS = rough;
    METALLIC = metal;
    SPECULAR = 0.5;
}
