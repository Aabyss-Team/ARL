import unittest
from app.services.fofaClient import fofa_query, FofaClient
from app.config import Config
from itertools import chain
from app import utils


class TestFofa(unittest.TestCase):
    def test_search(self):
        self.assertTrue(Config.FOFA_KEY != "")
        client = FofaClient(Config.FOFA_KEY,
                            page_size=10, max_page=3)

        results = list(chain.from_iterable(client.search('body = "test"')))
        self.assertTrue(len(results) == 30)

    def test_search_all(self):
        self.assertTrue(Config.FOFA_KEY != "")
        client = FofaClient(Config.FOFA_KEY,
                            page_size=10, max_page=3)

        query = 'domain = "baidu.com" && port = 80'

        data = client.fofa_search_all(query)

        print(f"Query: {data['query']}, Size: {data['size']}, Results: {len(data['results'])}")

        self.assertTrue(data["size"] > 30)
        self.assertTrue(len(data["results"]) == 10)

    def test_fofa_query(self):
        results = fofa_query('body = "test"',  page_size=10, max_page=3)
        self.assertTrue(len(results) == 30)

    def test_fofa_query_fields(self):
        results = fofa_query('body = "test"', fields="ip", page_size=10, max_page=3)
        for result in results:
            if not utils.is_vaild_ip_target(result):
                print(result, "is not a valid ip")
                self.assertTrue(False)

        self.assertTrue(len(results) == 30)


if __name__ == '__main__':
    unittest.main()
