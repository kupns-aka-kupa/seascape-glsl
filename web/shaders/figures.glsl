float
dot2(in vec2 v) {
  return dot(v, v);
}
float
dot2(in vec3 v) {
  return dot(v, v);
}
float
ndot(in vec2 a, in vec2 b) {
  return a.x * b.x - a.y * b.y;
}

float
sdU(in vec3 p, in float r, in float le, vec2 w) {
  p.x = (p.y > 0.0) ? abs(p.x) : length(p.xy);
  p.x = abs(p.x - r);
  p.y = p.y - le;
  float k = max(p.x, p.y);
  vec2  q = vec2((k < 0.0) ? -k : length(max(p.xy, 0.0)), abs(p.z)) - w;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float
sdPlane(vec3 p) {
  return p.y;
}

float
sdSphere(vec3 p, float s) {
  return length(p) - s;
}
float
sdCutSphere(in vec3 p, in float r, in float h) {
  float w = sqrt(r * r - h * h);// constant for a given shape

  vec2 q = vec2(length(p.xz), p.y);

  float s =
    max((h - r) * q.x * q.x + w * w * (h + r - 2.0 * q.y), h * q.x - w * q.y);

  return  length(q - vec2(w, h));
}

float
sdBox(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float
sdBoxFrame(vec3 p, vec3 b, float e) {
  p = abs(p) - b;
  vec3 q = abs(p + e) - e;

  return min(min(length(max(vec3(p.x, q.y, q.z), 0.0))
                   + min(max(p.x, max(q.y, q.z)), 0.0),
                 length(max(vec3(q.x, p.y, q.z), 0.0))
                   + min(max(q.x, max(p.y, q.z)), 0.0)),
             length(max(vec3(q.x, q.y, p.z), 0.0))
               + min(max(q.x, max(q.y, p.z)), 0.0));
}
float
sdEllipsoid(in vec3 p, in vec3 r)// approximated
{
  float k0 = length(p / r);
  float k1 = length(p / (r * r));
  return k0 * (k0 - 1.0) / k1;
}

float
sdTorus(vec3 p, vec2 t) {
  return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

/**
 * Caped torus
 * @param p position.
 * @param sc.
 * @param ra radius.
 * @param rb thick.
 */
float
sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb) {
  p.x = abs(p.x);
  float k = (sc.y * p.x > sc.x * p.y) ? dot(p.xy, sc) : length(p.xy);
  return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}

float
sdHexPrism(vec3 p, vec2 h) {
  vec3 q = abs(p);

  const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;
  vec2 d = vec2(length(p.xy - vec2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x))
                  * sign(p.y - h.x),
                p.z - h.y);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float
sdOctogonPrism(in vec3 p, in float r, float h) {
  const vec3 k = vec3(-0.9238795325,// sqrt(2+sqrt(2))/2
                      0.3826834323, // sqrt(2-sqrt(2))/2
                      0.4142135623);// sqrt(2)-1
  // reflections
  p = abs(p);
  p.xy -= 2.0 * min(dot(vec2(k.x, k.y), p.xy), 0.0) * vec2(k.x, k.y);
  p.xy -= 2.0 * min(dot(vec2(-k.x, k.y), p.xy), 0.0) * vec2(-k.x, k.y);
  // polygon side
  p.xy -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
  vec2 d = vec2(length(p.xy) * sign(p.y), p.z - h);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float
sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
  vec3  pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h) - r;
}

float
sdRoundCone(in vec3 p, in float r1, float r2, float h) {
  vec2 q = vec2(length(p.xz), p.y);

  float b = (r1 - r2) / h;
  float a = sqrt(1.0 - b * b);
  float k = dot(q, vec2(-b, a));

  if (k < 0.0)
    return length(q) - r1;
  if (k > a * h)
    return length(q - vec2(0.0, h)) - r2;

  return dot(q, vec2(a, b)) - r1;
}

float
sdRoundCone(vec3 p, vec3 a, vec3 b, float r1, float r2) {
  // sampling independent computations (only depend on shape)
  vec3  ba = b - a;
  float l2 = dot(ba, ba);
  float rr = r1 - r2;
  float a2 = l2 - rr * rr;
  float il2 = 1.0 / l2;

  // sampling dependant computations
  vec3  pa = p - a;
  float y = dot(pa, ba);
  float z = y - l2;
  float x2 = dot2(pa * l2 - ba * y);
  float y2 = y * y * l2;
  float z2 = z * z * l2;

  // single square root!
  float k = sign(rr) * rr * rr * x2;
  if (sign(z) * a2 * z2 > k)
    return sqrt(x2 + z2) * il2 - r2;
  if (sign(y) * a2 * y2 < k)
    return sqrt(x2 + y2) * il2 - r1;
  return (sqrt(x2 * a2 * il2) + y * rr) * il2 - r1;
}

float
sdTriPrism(vec3 p, vec2 h) {
  const float k = sqrt(3.0);
  h.x *= 0.5 * k;
  p.xy /= h.x;
  p.x = abs(p.x) - 1.0;
  p.y = p.y + 1.0 / k;
  if (p.x + k * p.y > 0.0)
    p.xy = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
  p.x -= clamp(p.x, -2.0, 0.0);
  float d1 = length(p.xy) * sign(-p.y) * h.x;
  float d2 = abs(p.z) - h.y;
  return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

// vertical
float
sdCylinder(vec3 p, vec2 h) {
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// vertical
float
sdCylinderSegment(vec3 p, vec2 h) {
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// arbitrary orientation
float
sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
  vec3  pa = p - a;
  vec3  ba = b - a;
  float baba = dot(ba, ba);
  float paba = dot(pa, ba);

  float x = length(pa * baba - ba * paba) - r * baba;
  float y = abs(paba - baba * 0.5) - baba * 0.5;
  float x2 = x * x;
  float y2 = y * y * baba;
  float d = (max(x, y) < 0.0)
              ? -min(x2, y2)
              : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
  return sign(d) * sqrt(abs(d)) / baba;
}
