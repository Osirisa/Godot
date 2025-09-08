shader_type canvas_item;

// Globale Palette (einmal zentral setzen):
uniform vec4 ui_surface;
uniform vec4 ui_outline;

// Pro Instanz:
uniform vec2 u_size;      // Control size in px
uniform float u_radius;   // corner radius
uniform float u_border;   // border width
uniform float u_notch_w;  // notch width (animiert)
uniform float u_notch_h;  // notch height (~ label box)
uniform float u_notch_x;  // notch center x in px

// SDF Hilfsfunktionen:
float sdRoundedRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - (b - vec2(r));
    return length(max(q, 0.0)) - r;
}

float sdRect(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return max(d.x, d.y);
}

void fragment() {
    vec2 p = (UV * u_size) - 0.5 * u_size; // Mittelpunkt = (0,0)

    // Grundform: Rounded Rect
    float d_base = sdRoundedRect(p, 0.5 * u_size, u_radius);

    // Notch als Rechteck am oberen Rand (Difference: base minus notch)
    vec2 notch_center = vec2(u_notch_x - 0.5 * u_size.x, -0.5 * u_size.y + u_notch_h * 0.5);
    float d_notch = sdRect(p - notch_center, vec2(u_notch_w * 0.5, u_notch_h * 0.5));

    // Difference: max(d_base, -d_notch)
    float d = max(d_base, -d_notch);

    // Border & Fill
    float aa = fwidth(d); // Antialias
    float border_mask = smoothstep(-u_border - aa, -u_border + aa, d);
    float fill_mask   = smoothstep(0.0 + aa, 0.0 - aa, d);

    vec4 col = mix(ui_surface, ui_outline, border_mask);
    COLOR = mix(vec4(0.0), col, max(fill_mask, border_mask));
}
