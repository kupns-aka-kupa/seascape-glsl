#define CHAR_BIT  8u
#define CHAR_MAX  0xffu
#define CHAR_MAXF float(CHAR_MAX)

#define rmask 0xff0000u
#define gmask 0x00ff00u
#define bmask 0x0000ffu
#define amask bmask

#define utov3(color)                                                           \
  (vec3(float((rmask & color) >> (CHAR_BIT * 2u)) / CHAR_MAXF,                 \
        float((gmask & color) >> CHAR_BIT) / CHAR_MAXF,                        \
        float(bmask & color) / CHAR_MAXF))

#define utov4(color)                                                           \
  (vec4(utov3(color >> CHAR_BIT), float(amask & color) / CHAR_MAXF))

#define WHITE_COLOR 0xdcdcdcu
#define BLUE_COLOR  0x007cadu
#define GREEN_COLOR 0x7ba05bu

struct object_info_t {
  vec3 position;
  vec3 scale;
  uint color;
};
