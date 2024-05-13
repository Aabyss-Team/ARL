import unittest
from app.utils.arl import gen_cip_map


class TestTaskHelpers(unittest.TestCase):
    def test_gen_cip_map_ip(self):
        task_id = "6535e8009ef7447c926a7249"

        cip_map = gen_cip_map(task_id)

        cip_list = list(cip_map.keys())

        for result in cip_list:
            print(result)

        self.assertTrue(len(cip_list) > 0)

    def test_gen_cip_map_domain(self):
        task_id = "64c26c58962e4f0ea83a2c4f"

        cip_map = gen_cip_map(task_id)

        cip_list = list(cip_map.keys())

        for result in cip_list:
            print(result)

        self.assertTrue(len(cip_list) > 0)


if __name__ == '__main__':
    unittest.main()
