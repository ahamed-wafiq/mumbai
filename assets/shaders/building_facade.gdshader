shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Mumbai Drive - High-Fidelity Procedural Architectural Facade Shader
// Renders realistic floor slabs, window grids, reflective glass, and warm interior glow

uniform vec4 wall_color : source_color = vec4(0.82, 0.76, 0.68, 1.0);
uniform vec4 window_color : source_color = vec4(0.12, 0.18, 0.25, 1.0);
uniform vec4 trim_color : source_color = vec4(1.0, 0.42, 0.0, 1.0); // Mumbai Art Deco Orange

uniform float floor_height : hint_range(2.0, 6.0) = 3.6;
uniform float window_width : hint_range(0.2, 0.9) = 0.65;
uniform float window_height : hint_range(0.2, 0.9) = 0.55;
uniform float window_roughness : hint_range(0.0, 1.0) = 0.12;
uniform float wall_roughness : hint_range(0.0, 1.0) = 0.75;
uniform float glass_metallic : hint_range(0.0, 1.0) = 0.85;

uniform float emission_strength : hint_range(0.0, 3.0) = 1.2;
uniform vec4 emission_color : source_color = vec4(1.0, 0.88, 0.65, 1.0);

varying vec3 v_world_pos;
varying vec3 v_normal;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    // Check if surface is a flat roof (normal pointing predominantly upward)
    if (abs(v_normal.y) > 0.6) {
        // Flat roof surface (tar / concrete aggregate with subtle trim)
        ALBEDO = vec3(0.22, 0.24, 0.27);
        ROUGHNESS = 0.9;
        METALLIC = 0.1;
        EMISSION = vec3(0.0);
        return;
    }

    // Vertical facade walls
    float y = v_world_pos.y;
    
    // Compute horizontal projection along facade direction
    float horizontal_coord = (abs(v_normal.x) > abs(v_normal.z)) ? v_world_pos.z : v_world_pos.x;
    float window_spacing = 3.2; // 3.2m per window column
    
    // UV-like coordinates for floor and window grid
    float floor_fraction = mod(y, floor_height) / floor_height;
    float col_fraction = mod(horizontal_coord, window_spacing) / window_spacing;
    
    // Window region logic
    bool in_window_y = (floor_fraction > (1.0 - window_height) * 0.5) && (floor_fraction < 1.0 - (1.0 - window_height) * 0.5);
    bool in_window_x = (col_fraction > (1.0 - window_width) * 0.5) && (col_fraction < 1.0 - (1.0 - window_width) * 0.5);
    bool is_window = in_window_y && in_window_x && (y > 2.5); // Ground floor has storefront / entry
    
    // Ground floor storefront accent
    if (y < 3.2) {
        float shop_col = mod(horizontal_coord, 5.0) / 5.0;
        bool is_shop_glass = (shop_col > 0.15 && shop_col < 0.85) && (y > 0.5 && y < 2.8);
        if (is_shop_glass) {
            ALBEDO = window_color.rgb * 0.7;
            ROUGHNESS = 0.15;
            METALLIC = 0.6;
            EMISSION = emission_color.rgb * 0.6;
            return;
        }
    }
    
    if (is_window) {
        // Reflective architectural glass
        ALBEDO = window_color.rgb;
        ROUGHNESS = window_roughness;
        METALLIC = glass_metallic;
        
        // Window mullion / window frame borders
        float frame_edge_x = min(col_fraction - (1.0 - window_width) * 0.5, (1.0 - (1.0 - window_width) * 0.5) - col_fraction);
        float frame_edge_y = min(floor_fraction - (1.0 - window_height) * 0.5, (1.0 - (1.0 - window_height) * 0.5) - floor_fraction);
        if (frame_edge_x < 0.03 || frame_edge_y < 0.04) {
            // Dark window frame
            ALBEDO = vec3(0.08, 0.09, 0.11);
            ROUGHNESS = 0.5;
            METALLIC = 0.3;
            EMISSION = vec3(0.0);
        } else {
            // Pseudorandom interior lights on at dusk/evening
            float window_hash = fract(sin(dot(floor(vec2(y / floor_height, horizontal_coord / window_spacing)), vec2(12.9898, 78.233))) * 43758.5453);
            if (window_hash > 0.45) {
                // Lit room interior
                EMISSION = emission_color.rgb * emission_strength * (0.6 + 0.4 * window_hash);
            } else {
                // Dark reflective pane
                EMISSION = vec3(0.0);
            }
        }
    } else {
        // Solid wall facade with floor slab accent trims
        bool is_floor_band = (floor_fraction < 0.08);
        if (is_floor_band) {
            // Architectural horizontal floor cornice / trim
            ALBEDO = mix(wall_color.rgb, trim_color.rgb, 0.35);
            ROUGHNESS = wall_roughness * 0.85;
            METALLIC = 0.1;
        } else {
            ALBEDO = wall_color.rgb;
            ROUGHNESS = wall_roughness;
            METALLIC = 0.05;
        }
        EMISSION = vec3(0.0);
    }
}
