import unittest
from app.utils import normal_url


class TestNormalURL(unittest.TestCase):
    def test_normal_url(self):
        u1 = "https://www.baidu.com:443/test?a=1"
        u2 = "https://www.baidu.com/test?a=1"
        normal1 = normal_url(u1)

        self.assertTrue(normal1 == u2)


