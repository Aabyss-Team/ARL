import unittest
from app.services import domain_site_update


class TestDomainSiteUpdate(unittest.TestCase):
    def test_domain_site_update(self):
        domain_site_update("64b7d749c97bead7f83d0de4", ["www.qq.com","qqgame.qq.com","mail.weread.qq.com"], "test")


if __name__ == '__main__':
    unittest.main()
