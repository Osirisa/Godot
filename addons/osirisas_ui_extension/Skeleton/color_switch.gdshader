shader_type canvas_item;

/* Basisfarben */
uniform vec4 color_a : source_color = vec4(0.22, 0.22, 0.24, 1.0);
uniform vec4 color_b : source_color = vec4(0.95, 0.95, 0.98, 1.0);

/* Animation/Shape */
uniform float speed : hint_range(0.0, 10.0) = 1.2;      // Zyklen pro Sekunde
uniform float duty  : hint_range(0.01, 0.99) = 0.5;     // Asymmetrie: Anteil Aufwärts-Phase (0..1)
uniform float shape : hint_range(0.2, 4.0)  = 1.0;      // Kurvenschärfe: <1 weich, >1 spitz
uniform float phase : hint_range(0.0, 1.0)  = 0.0;      // Phasenoffset (0..1)

/* Mix-Klemmung: nie ganz A/B, z.B. 0.2..0.9 */
uniform float mix_min : hint_range(0.0, 1.0) = 0.0;
uniform float mix_max : hint_range(0.0, 1.0) = 1.0;

/* Optionaler globaler Alpha-Multiplikator */
uniform float alpha_mul : hint_range(0.0, 1.0) = 1.0;

/* Asymmetrische Dreieckswelle 0..1 mit Duty-Cycle */
float tri_asym(float x, float d) {
    x = fract(x);
    d = clamp(d, 0.001, 0.999);
    if (x < d) {
        return x / d;                  // 0 -> 1 in d
    } else {
        return 1.0 - (x - d) / (1.0 - d); // 1 -> 0 in 1-d
    }
}

/* Kurven-Shaping (Pow) + Clamp in mix_min..mix_max */
float shaped_mix(float t, float k, float lo, float hi) {
    // Symmetrische Pow-Form ohne Flip:
    float s = pow(t, k);
    return mix(lo, hi, clamp(s, 0.0, 1.0));
}

void fragment() {
    float t = TIME * speed + phase;        // Zeit + Phase
    float w = tri_asym(t, duty);           // 0..1 asy. Dreieck
    float m = shaped_mix(w, shape, mix_min, mix_max);
    vec4 col = mix(color_a, color_b, m);

    // Falls Textur vorhanden (z. B. 9-Patch/Panel), moduliere sie:
    vec4 tex = texture(TEXTURE, UV);
    col.rgb = mix(col.rgb, col.rgb * tex.rgb, step(0.0, TEXTURE_PIXEL_SIZE.x)); // „verwenden, wenn da“
    col.a *= alpha_mul * tex.a;

    COLOR = col;
}
