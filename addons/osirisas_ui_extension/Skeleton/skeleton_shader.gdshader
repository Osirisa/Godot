shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.86, 0.86, 0.86, 1.0); // Grundfarbe
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Glanz
uniform float speed : hint_range(0.0, 4.0) = 1.2;     // Animationsgeschw.
uniform float band_width : hint_range(0.05, 1.0) = 0.25; // Breite der Glanzspur
uniform float angle_deg : hint_range(-90.0, 90.0) = 20.0; // Winkel in Grad

void fragment() {
    vec2 uv = UV;
    // Winkel
    float a = radians(angle_deg);
    // Diagonal verlaufende Koordinate
    float d = uv.x * cos(a) + uv.y * sin(a);
    // Zeitverschiebung
    float t = TIME * speed;
    // Gleiten lassen (0..1)
    float pos = fract(d - t);
    // Sanfte Bande
    float band = smoothstep(0.0, band_width, pos) * (1.0 - smoothstep(band_width, band_width * 2.0, pos));
    // Finalfarbe
    vec4 col = mix(base_color, highlight_color, band * 0.6);
    COLOR = col * texture(TEXTURE, UV);
}
