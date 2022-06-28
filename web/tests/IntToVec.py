import unittest

rmask = 0xff0000
gmask = 0x00ff00
bmask = 0x0000ff

amask = bmask

CHAR_BIT = 8


def itov3(color):
    print('0x%08x' % color)
    return (float((rmask & color) >> (CHAR_BIT * 2)), float((gmask & color) >> CHAR_BIT),
            float(bmask & color))


def itov4(color):
    print('0x%08x' % color)
    return (*itov3(color >> CHAR_BIT),
            float((amask & color)))


class IntToVec3TestCase(unittest.TestCase):
    def test_convert(self):
        self.assertEqual(itov3(0xdcdcdc), (0xdc, 0xdc, 0xdc))
        self.assertEqual(itov3(0x007cad), (0x00, 0x7c, 0xad))
        self.assertEqual(itov3(0x7ba05b), (0x7b, 0xa0, 0x5b))


class IntToVec4TestCase(unittest.TestCase):
    def test_convert(self):
        self.assertEqual(itov4(0xdcdcdc11), (0xdc, 0xdc, 0xdc, 0x11))
        self.assertEqual(itov4(0x007cad12), (0x00, 0x7c, 0xad, 0x12))
        self.assertEqual(itov4(0x7ba05b55), (0x7b, 0xa0, 0x5b, 0x55))


if __name__ == '__main__':
    unittest.main()
