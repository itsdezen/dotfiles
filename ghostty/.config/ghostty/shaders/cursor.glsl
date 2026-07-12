// Kanagawa cursor shader: three independent cursor behaviors, toggled below.
// - smooth: cursor glides (VS Code-style) from its previous position/size to the current one
// - blaze:  directional glow trail shaped by the cursor's movement, then fades
// - smear:  bright streak swiping from the previous to the current cursor position, flash-fades out

// ---- behavior flags ----
const bool ENABLE_SMOOTH = true;
const bool ENABLE_BLAZE = true;
const bool ENABLE_SMEAR = true;

// ---- shared kanagawa yellow palette (used by blaze and smear) ----
const vec4 ACCENT_COLOR = vec4(0.714, 0.573, 0.482, 1.0); // dragonOrange #b6927b (inner, darker)
const vec4 ACCENT_COLOR_BRIGHT = vec4(1.0, 0.620, 0.231, 1.0); // roninYellow #ff9e3b (outer, brighter)

float sdRectangle(in vec2 p, in vec2 center, in vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec2 norm(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}

// distance from p to segment a-b; h is the projection factor (0 at a, 1 at b)
float sdSegment(vec2 p, vec2 a, vec2 b, out float h) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

// ---- blaze: kanagawa-colored glow that flashes and fades around the cursor ----

const float BLAZE_DURATION = 0.3; // seconds
const float BLAZE_SIZE_SCALE = 0.55; // shrinks the glow halo reach (1.0 = full trail length)

float easeBlaze(float x) {
    return pow(1.0 - x, 3.0);
}

vec4 applyBlaze(vec4 baseColor, vec2 fragCoord) {
    vec2 vu = norm(fragCoord, 1.);

    vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);

    float sdfCurrentCursor = sdRectangle(vu, centerCC, currentCursor.zw * 0.5);

    float progress = clamp((iTime - iTimeCursorChange) / BLAZE_DURATION, 0.0, 1.0);
    float easedProgress = easeBlaze(progress);
    float lineLength = distance(centerCC, centerCP) * BLAZE_SIZE_SCALE;

    vec4 trail = mix(ACCENT_COLOR, baseColor, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
    trail = mix(ACCENT_COLOR_BRIGHT, trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
    return mix(trail, baseColor, 1. - smoothstep(0., sdfCurrentCursor, easedProgress * lineLength));
}

// ---- smear: light-streak swipe from the previous to the current cursor position ----

const float SMEAR_DURATION = 0.18; // seconds
const float SMEAR_WIDTH_SCALE = 0.9; // streak thickness relative to cursor height
const float SMEAR_TAPER = 0.6; // how much the tail end narrows (0 = uniform width, 1 = fully pointed)

float easeSmear(float x) {
    return pow(1.0 - x, 2.0);
}

vec4 applySmear(vec4 baseColor, vec2 fragCoord) {
    vec2 vu = norm(fragCoord, 1.);

    vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

    vec2 head = getRectangleCenter(currentCursor);
    vec2 tail = getRectangleCenter(previousCursor);

    float progress = clamp((iTime - iTimeCursorChange) / SMEAR_DURATION, 0.0, 1.0);
    if (progress >= 1.0) {
        return baseColor;
    }
    float fade = easeSmear(progress);

    float t;
    float dist = sdSegment(vu, tail, head, t);

    float halfWidth = currentCursor.w * 0.5 * SMEAR_WIDTH_SCALE * mix(1.0 - SMEAR_TAPER, 1.0, t);
    float mask = 1.0 - smoothstep(0.0, halfWidth + 0.002, dist);

    vec4 flashColor = mix(ACCENT_COLOR, ACCENT_COLOR_BRIGHT, t);
    float alpha = mask * fade;

    return mix(baseColor, flashColor, alpha);
}

// ---- smooth move: cursor rectangle glides to its new position/size ----

const float MOVE_DURATION = 0.1; // seconds

float easeMove(float x) {
    float t = 1.0 - x;
    return 1.0 - t * t * t;
}

vec4 applySmoothMove(vec4 baseColor, vec2 fragCoord) {
    float progress = clamp((iTime - iTimeCursorChange) / MOVE_DURATION, 0.0, 1.0);
    if (progress >= 1.0) {
        return baseColor;
    }
    float eased = easeMove(progress);

    float invResY = 1.0 / iResolution.y;
    float scale = 2.0 * invResY;
    vec2 normOffset = iResolution.xy * invResY;

    vec2 currentPos = iCurrentCursor.xy * scale - normOffset;
    vec2 previousPos = iPreviousCursor.xy * scale - normOffset;
    vec2 currentSize = iCurrentCursor.zw * scale;
    vec2 previousSize = iPreviousCursor.zw * scale;

    vec2 pos = mix(previousPos, currentPos, eased);
    vec2 size = mix(previousSize, currentSize, eased);
    vec2 halfSize = size * 0.5;
    vec2 center = pos + vec2(halfSize.x, -halfSize.y);

    vec2 normCoord = fragCoord * scale - normOffset;
    float sdf = sdRectangle(normCoord, center, halfSize);

    float aaWidth = scale;
    float alpha = 1.0 - smoothstep(-aaWidth, aaWidth, sdf);

    vec4 result = baseColor;
    result.rgb = mix(result.rgb, iCurrentCursorColor.rgb, alpha * iCurrentCursorColor.a);
    return result;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 color = texture(iChannel0, fragCoord / iResolution.xy);
    // smoothMove must run first: it paints the solid cursor block at its
    // glided position, so blaze/smear flashes stay on top instead of
    // getting overwritten by it.
    if (ENABLE_SMOOTH) {
        color = applySmoothMove(color, fragCoord);
    }
    if (ENABLE_BLAZE) {
        color = applyBlaze(color, fragCoord);
    }
    if (ENABLE_SMEAR) {
        color = applySmear(color, fragCoord);
    }
    fragColor = color;
}
