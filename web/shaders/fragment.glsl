//#version 330 core

uniform vec3  iResolution;
uniform float iTime;
uniform vec4  iMouse;

#include <figures.glsl>
#include <global.glsl>
#include <material.glsl>

#define AA 1

//------------------------------------------------------------------

vec2
opU(vec2 d1, vec2 d2) {
  return (d1.x < d2.x) ? d1 : d2;
}

//------------------------------------------------------------------

#define ZERO (0)

#define BOX_POSITION_OFFSET vec3(0.5, 0.0, 0.0)
#define BOX_SCALE           vec3(0.2, 0.07, 0.2)

#define CYLINDER_POSITION_OFFSET vec3(0.0, 0.25, 0.0)
#define CYLINDER_SCALE           vec2(0.15, 0.25)

object_info_t BOX = object_info_t(BOX_POSITION_OFFSET, BOX_SCALE, WHITE_COLOR);
object_info_t CYLINDER_SEGMENT = object_info_t(CYLINDER_POSITION_OFFSET,
                                               vec3(CYLINDER_SCALE, .0),
                                               GREEN_COLOR);

//------------------------------------------------------------------

vec2
map(in vec3 pos) {
  vec2 res = vec2(1e10, 0.0);

  // bounding box
  if (sdBox(pos - vec3(1.0, 0.3, -1.0), vec3(0.35, 0.3, 2.5)) < res.x) {
    res = opU(
      res,
      vec2(sdCylinderSegment(pos - CYLINDER_POSITION_OFFSET, CYLINDER_SCALE),
           3.0));
    res = opU(res, vec2(sdBox(pos - BOX_POSITION_OFFSET, BOX_SCALE), 3.0));
  }

  return res;
}

// https://iquilezles.org/articles/boxfunctions
vec2
iBox(in vec3 ro, in vec3 rd, in vec3 rad) {
  vec3 m = 1.0 / rd;
  vec3 n = m * ro;
  vec3 k = abs(m) * rad;
  vec3 t1 = -n - k;
  vec3 t2 = -n + k;
  return vec2(max(max(t1.x, t1.y), t1.z), min(min(t2.x, t2.y), t2.z));
}

vec2
raycast(in vec3 ro, in vec3 rd) {
  vec2 res = vec2(-1.0, -1.0);

  float tmin = 1.0;
  float tmax = 20.0;

  // raytrace floor plane
  float tp1 = (0.0 - ro.y) / rd.y;
  if (tp1 > 0.0) {
    tmax = min(tmax, tp1);
    res = vec2(tp1, 1.0);
  }
  //else return res;

  // raymarch primitives
  vec2 tb = iBox(ro - vec3(0.0, 0.4, -0.5), rd, vec3(2.5, 0.41, 3.0));
  if (tb.x < tb.y && tb.y > 0.0 && tb.x < tmax) {
    //return vec2(tb.x,2.0);
    tmin = max(tb.x, tmin);
    tmax = min(tb.y, tmax);

    float t = tmin;
    for (int i = 0; i < 70 && t < tmax; i++) {
      vec2 h = map(ro + rd * t);
      if (abs(h.x) < (0.0001 * t)) {
        res = vec2(t, h.y);
        break;
      }
      t += h.x;
    }
  }

  return res;
}

// https://iquilezles.org/articles/rmshadows
float
calcSoftshadow(in vec3 ro, in vec3 rd, in float mint, in float tmax) {
  // bounding volume
  float tp = (0.8 - ro.y) / rd.y;
  if (tp > 0.0)
    tmax = min(tmax, tp);

  float res = 1.0;
  float t = mint;
  for (int i = ZERO; i < 24; i++) {
    float h = map(ro + rd * t).x;
    float s = clamp(8.0 * h / t, 0.0, 1.0);
    res = min(res, s * s * (3.0 - 2.0 * s));
    t += clamp(h, 0.02, 0.2);
    if (res < 0.004 || t > tmax)
      break;
  }
  return clamp(res, 0.0, 1.0);
}

// https://iquilezles.org/articles/normalsSDF
vec3
calcNormal(in vec3 pos) {
#if 0
  vec2 e = vec2(1.0, -1.0)*0.5773*0.0005;
  return normalize(e.xyy*map(pos + e.xyy).x +
  e.yyx*map(pos + e.yyx).x +
  e.yxy*map(pos + e.yxy).x +
  e.xxx*map(pos + e.xxx).x);
#else
  // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
  vec3 n = vec3(0.0);
  for (int i = ZERO; i < 4; i++) {
    vec3 e =
      0.5773
      * (2.0 * vec3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.0);
    n += e * map(pos + 0.0005 * e).x;
    //if( n.x+n.y+n.z>100.0 ) break;
  }
  return normalize(n);
#endif
}

// https://iquilezles.org/articles/nvscene2008/rwwtt.pdf
float
calcAO(in vec3 pos, in vec3 nor) {
  float occ = 0.0;
  float sca = 1.0;
  for (int i = ZERO; i < 5; i++) {
    float h = 0.01 + 0.12 * float(i) / 4.0;
    float d = map(pos + h * nor).x;
    occ += (h - d) * sca;
    sca *= 0.95;
    if (occ > 0.35)
      break;
  }
  return clamp(1.0 - 3.0 * occ, 0.0, 1.0) * (0.5 + 0.5 * nor.y);
}

vec3
render(in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy) {
  // background
  vec3 col = vec3(0.7, 0.7, 0.9) - max(rd.y, 0.0) * 0.3;

  // raycast scene
  uvec3 test = uvec3(0);
  vec2  res = raycast(ro, rd);
  float t = res.x;
  float flag = res.y;
  if (flag > -0.5) {
    vec3 pos = ro + t * rd;
    vec3 nor = (flag < 1.5) ? vec3(0.0, 1.0, 0.0) : calcNormal(pos);
    vec3 ref = reflect(rd, nor);

    // material
    col = utov3(GREEN_COLOR);
    float ks = 1.0;

    if (flag < 1.5) {
      // project pixel footprint into the plane
      vec3 dpdx = ro.y * (rd / rd.y - rdx / rdx.y);
      vec3 dpdy = ro.y * (rd / rd.y - rdy / rdy.y);

      float f = checkersGradBox(3.0 * pos.xz, 3.0 * dpdx.xz, 3.0 * dpdy.xz);
      col = 0.15 + f * vec3(0.05);
      ks = 0.4;
    }

    // lighting
    float occ = calcAO(pos, nor);

    vec3 lin = vec3(0.0);

    // sun
    {
      vec3  lig = normalize(vec3(-0.5, 0.4, -0.6));
      vec3  hal = normalize(lig - rd);
      float dif = clamp(dot(nor, lig), 0.0, 1.0);
      //if( dif>0.0001 )
      dif *= calcSoftshadow(pos, lig, 0.02, 2.5);
      float spe = pow(clamp(dot(nor, hal), 0.0, 1.0), 16.0);
      spe *= dif;
      spe *= 0.04 + 0.96 * pow(clamp(1.0 - dot(hal, lig), 0.0, 1.0), 5.0);
      //spe *= 0.04+0.96*pow(clamp(1.0-sqrt(0.5*(1.0-dot(rd,lig))),0.0,1.0),5.0);
      lin += col * 2.20 * dif * vec3(1.30, 1.00, 0.70);
      lin += 5.00 * spe * vec3(1.30, 1.00, 0.70) * ks;
    }
    // sky
    {
      float dif = sqrt(clamp(0.5 + 0.5 * nor.y, 0.0, 1.0));
      dif *= occ;
      float spe = smoothstep(-0.2, 0.2, ref.y);
      spe *= dif;
      spe *= 0.04 + 0.96 * pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 5.0);
      //if( spe>0.001 )
      spe *= calcSoftshadow(pos, ref, 0.02, 2.5);
      lin += col * 0.60 * dif * vec3(0.40, 0.60, 1.15);
      lin += 2.00 * spe * vec3(0.40, 0.60, 1.30) * ks;
    }
    // back
    {
      float dif = clamp(dot(nor, normalize(vec3(0.5, 0.0, 0.6))), 0.0, 1.0)
                  * clamp(1.0 - pos.y, 0.0, 1.0);
      dif *= occ;
      lin += col * 0.55 * dif * vec3(0.25, 0.25, 0.25);
    }
    // sss
    {
      float dif = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);
      dif *= occ;
      lin += col * 0.25 * dif * vec3(1.00, 1.00, 1.00);
    }

    col = lin;

    col = mix(col, vec3(0.7, 0.7, 0.9), 1.0 - exp(-0.0001 * t * t * t));
  }

  return vec3(clamp(col, 0.0, 1.0));
}

mat3
setCamera(in vec3 ro, in vec3 ta, float cr) {
  vec3 cw = normalize(ta - ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize(cross(cw, cp));
  vec3 cv = (cross(cu, cw));
  return mat3(cu, cv, cw);
}

void
mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2  mo = iMouse.xy / iResolution.xy;
  float time = 32.0 + 1.5;

  // camera
  vec3 ta = vec3(0.0, -0.0, -0.0);
  vec3 ro = ta + vec3(cos(time + mo.x), 2.0 + mo.y, sin(time + mo.x));
  // camera-to-world transformation
  mat3 ca = setCamera(ro, ta, 0.0);

  vec3 tot = vec3(0.0);
#if AA > 1
  for (int m = ZERO; m < AA; m++)
    for (int n = ZERO; n < AA; n++) {
      // pixel coordinates
      vec2 o = vec2(float(m), float(n)) / float(AA) - 0.5;
      vec2 p = (2.0 * (fragCoord + o) - iResolution.xy) / iResolution.y;
#else
  vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
#endif

      // focal length
      const float fl = 2.5;

      // ray direction
      vec3 rd = ca * normalize(vec3(p, fl));

      // ray differentials
      vec2 px =
        (2.0 * (fragCoord + vec2(1.0, 0.0)) - iResolution.xy) / iResolution.y;
      vec2 py =
        (2.0 * (fragCoord + vec2(0.0, 1.0)) - iResolution.xy) / iResolution.y;
      vec3 rdx = ca * normalize(vec3(px, fl));
      vec3 rdy = ca * normalize(vec3(py, fl));

      // render
      vec3 col = render(ro, rd, rdx, rdy);

      // gain
      // col = col*3.0/(2.5+col);

      // gamma
      col = pow(col, vec3(0.4545));

      tot += col;
#if AA > 1
    }
  tot /= float(AA * AA);
#endif

  fragColor = vec4(tot, 1.0);
}

void
main() {
  mainImage(gl_FragColor, gl_FragCoord.xy);
}
