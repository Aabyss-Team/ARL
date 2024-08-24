from unittest import TestCase
from app.services import expr
import timeit


class TestExpression(TestCase):
    def test_valid_expressions(self):
        test_cases = [
            ('ab = "abc"', False),
            ('!(body == "jeecms" && body == "http://wwwjeecms.com") && body != "powered by"', True),
            ('(title == "jeecms" && body="http://wwwjeecms.com") || header = "powered by jeecms"', True),
            ('(title=="jeecms"&&body="http://wwwjeecms.com")||header="powered by jeecms"', True),
        ]

        for expression, expected_result in test_cases:
            with self.subTest(expression=expression):
                self.assertEqual(expr.check_expression(expression), expected_result)

    def test_eval_expressions(self):
        test_cases = [
            ('icon_hash == "116323821"', True),
            ('body = "test" && icon_hash == "116323821"', True),
            ('body = "test" || icon_hash == "11111111"', True),
            ('body = "test3" && icon_hash == "11111111"', False),
            ('!(body = "test3" && icon_hash == "11111111")', True),
            ('header == "header test2"', True),
            ('body == "body test1" || icon_hash = "116323821"', True),
            ('title = "title \\" test3"', True),
            ('title == "title \\" test3"', True),
            ('title = " \\" "', True),
            ('icon_hash != "11111111"', True),
            ('body != "test" && icon_hash != "116323821"', False),
            ('body="test"&&icon_hash=="116323821"', True),
            ('body="test"&&body!="<"', False),
            ('body=="body test1<"', True),
            ('body="body test1<"', True),
            ('body="test"&&body="<"', True),
            ('!(body="test")', False),
            ('!body="test"', False),
        ]

        variables = {
            'body': "body test1<",
            'header': "header test2",
            'title': "title \" test3",
            'icon_hash': "116323821"
        }

        for expression, expected_result in test_cases:
            with self.subTest(expression=expression):
                self.assertEqual(expr.evaluate(expression, variables), expected_result)

    def test_eval_bench(self):
        expression = 'body = "body_test" && status_code == "200" && header = "header" && title = "title \\""'
        variables = {
            'body': "body" * 1024 * 100 + "_test",
            'header': "header test2",
            'title': "title \" test3",
            'icon_hash': "116323821"
        }

        print(timeit.timeit(lambda: expr.evaluate(expression, variables), number=1000))

        parsed = expr.parse_expression(expression)
        print(timeit.timeit(lambda: expr.evaluate_expression(parsed, variables), number=1000))


