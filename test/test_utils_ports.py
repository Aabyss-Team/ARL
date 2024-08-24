import unittest
from app.utils import is_valid_exclude_ports


class TestExcludePortsValidation(unittest.TestCase):
    def test_valid_single_port(self):
        self.assertTrue(is_valid_exclude_ports("80"))

    def test_valid_multiple_ports(self):
        self.assertTrue(is_valid_exclude_ports("80,443"))

    def test_valid_range(self):
        self.assertTrue(is_valid_exclude_ports("8080-8089"))

    def test_valid_combination(self):
        self.assertTrue(is_valid_exclude_ports("80,443,8080-8089"))

    def test_invalid_range_reversed(self):
        self.assertFalse(is_valid_exclude_ports("8089-8080"))

    def test_invalid_port_too_large(self):
        self.assertFalse(is_valid_exclude_ports("80,70000"))

    def test_invalid_non_numeric(self):
        self.assertFalse(is_valid_exclude_ports("80,http"))

    def test_invalid_empty_string(self):
        self.assertFalse(is_valid_exclude_ports(""))

    def test_invalid_syntax_letters(self):
        self.assertFalse(is_valid_exclude_ports("abc-def"))

    def test_invalid_syntax_letters_and_numbers(self):
        self.assertFalse(is_valid_exclude_ports("80-1-2,"))


if __name__ == '__main__':
    unittest.main()