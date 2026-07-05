// Kanagawa cursor shader: a yellow/orange blaze glows around the cursor after
// it moves, while the cursor itself glides smoothly (VS Code-style) from its
// previous position/size to the current one instead of jumping instantly.

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

// ---- blaze: kanagawa-colored glow that flashes and fades around the cursor ----

const vec4 TRAIL_COLOR = vec4(0.902, 0.765, 0.518, 1.0); // kanagawa carpYellow #e6c384 (inner)
const vec4 TRAIL_COLOR_ACCENT = vec4(1.0, 0.620, 0.231, 1.0); // kanagawa roninYellow #ff9e3b (outer)
const float BLAZE_DURATION = 0.3; // seconds

float easeBlaze(float x) {
    return pow(1.0 - x, 3.0);
}

vec4 applyBlaze(vec4 baseColor, vec2 fragCoord) {
    vec2 vu = norm(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);

    float sdfCurrentCursor = sdRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);

    float progress = clamp((iTime - iTimeCursorChange) / BLAZE_DURATION, 0.0, 1.0);
    float easedProgress = easeBlaze(progress);
    float lineLength = distance(centerCC, centerCP);

    vec4 trail = mix(TRAIL_COLOR_ACCENT, baseColor, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
    trail = mix(TRAIL_COLOR, trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
    return mix(trail, baseColor, 1. - smoothstep(0., sdfCurrentCursor, easedProgress * lineLength));
}

// ---- smooth move: cursor rectangle glides to its new position/size ----

const float MOVE_DURATION = 0.3; // seconds

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
    vec4 background = texture(iChannel0, fragCoord / iResolution.xy);
    vec4 withBlaze = applyBlaze(background, fragCoord);
    fragColor = applySmoothMove(withBlaze, fragCoord);
}
