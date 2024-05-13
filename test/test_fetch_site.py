import unittest
from app import services


class TestDomain(unittest.TestCase):
    def test_fetch_site(self):
        sites = ["https://www.baidu.com"]
        data = services.fetch_site(sites, concurrency=2)
        self.assertTrue(len(data) >= 1)
        self.assertTrue(len(data[0]["finger"]) >= 3)
        self.assertTrue(len(data[0]["favicon"]["data"]) >= 10)
        self.assertTrue(data[0]["favicon"]["hash"] == -1588080585)

    def test_example(self):
        sites = ["https://www.example.com/"]
        data = services.fetch_site(sites, concurrency=2)
        self.assertTrue(len(data) == 1)
        self.assertTrue(data[0]["status"] == 200)
        self.assertTrue(data[0]["title"] == "Example Domain")

    def test_fetch_data(self):
        sites = ["https://mtp.myoas.com"]
        data = services.fetch_site(sites, concurrency=2)
        self.assertTrue(len(data) == 2)
        self.assertTrue(data[1]["status"] == 200)


if __name__ == '__main__':
    unittest.main()
