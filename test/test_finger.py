from unittest import TestCase
from app.services import finger_db_cache, finger_db_identify, have_human_rule_from_db
from app import utils
import timeit
import yaml


class TestExpression(TestCase):
    def test_finger_db_identify(self):
        finger_db_cache.update_cache()

        variables = {
            'body': "body" * 1024 * 100 + "_test",
            'header': "header test2",
            'title': "title \" test3",
            'icon_hash': "116323821",
        }

        results = finger_db_identify(variables)
        print(results)

        print(timeit.timeit(lambda: finger_db_identify(variables), number=1000))

    def test_have_human_rule_from_db(self):
        test_cases = [
            ('icon_hash="116323821"', True),
            ('icon_hash="2062026853"', True),
            ('body = "test" || icon_hash == "11111111"', False),
            ('icon_hash="2062026853"  ', False),
        ]

        for expression, expected_result in test_cases:
            with self.subTest(expression=expression):
                self.assertEqual(have_human_rule_from_db(expression), expected_result)

    def test_dump_yaml(self):
        items = []
        results = list(utils.conn_db('fingerprint').find())
        cnt = 0
        for result in results:
            item = dict()
            item["name"] = result["name"]
            item["rule"] = result["human_rule"]
            items.append(item)
            cnt += 1
            if cnt > 10:
                continue

        data = yaml.dump(items, default_flow_style=False, sort_keys=False, allow_unicode=True)
        print(data)