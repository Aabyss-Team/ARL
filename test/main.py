import unittest
import os


class RunCase(unittest.TestCase):
    def test_case(self):
        case_path = os.getcwd()
        discover = unittest.defaultTestLoader.discover(case_path, pattern="test_*.py")
        runner = unittest.TextTestRunner(verbosity=2)
        test_unit = unittest.TestSuite()
        for test_suite in discover:
            for test_case in test_suite:
                test_unit.addTest(test_case)
        runner.run(test_unit)


if __name__ == '__main__':
    unittest.main()
