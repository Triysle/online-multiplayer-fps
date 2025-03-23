shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 pulse_color : source_color = vec4(1.0, 1.0, 0.3, 1.0);
uniform float pulse_rate : hint_range(0.1, 5.0) = 2.0;
uniform bool is_pulsing = false;
uniform bool is_recharging = false;

void fragment() {
    vec4 final_color = base_color;
    
    if (is_pulsing) {
        float pulse = (sin(TIME * pulse_rate) + 1.0) / 2.0;
        final_color = mix(base_color, pulse_color, pulse);
    }
    
    if (is_recharging) {
        float recharge_effect = (sin(TIME * 3.0) + 1.0) / 2.0 * 0.2;
        final_color = mix(final_color, vec4(1.0, 1.0, 1.0, 1.0), recharge_effect);
    }
    
    COLOR = final_color;
}